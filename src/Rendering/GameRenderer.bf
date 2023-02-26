using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;
using ImGui;

namespace Meteorite;

class GameRenderer {
	private Meteorite me = .INSTANCE;

	private append Attachments attachments = .();

	private int mainColorI = -1;
	public GpuImage MainColor => attachments.Get(mainColorI);

	private int mainNormalI = -1;
	public GpuImage MainNormal => attachments.Get(mainNormalI);

	private int mainDepthI = -1;
	public GpuImage MainDepth => attachments.Get(mainDepthI);

	private int smaaEdgesI = -1;
	public GpuImage SmaaEdges => attachments.Get(smaaEdgesI);

	private int smaaBlendI = -1;
	public GpuImage SmaaBlend => attachments.Get(smaaBlendI);

	public Descriptor MainColorDescriptor => .SampledImage(MainColor, Gfxa.LINEAR_SAMPLER);
	public Descriptor MainNormalDescriptor => .SampledImage(MainNormal, Gfxa.NEAREST_SAMPLER);
	public Descriptor MainDepthDescriptor => .SampledImage(MainDepth, Gfxa.NEAREST_SAMPLER);

	private GpuImage smaaArea ~ ReleaseAndNullify!(_);
	private GpuImage smaaSearch ~ ReleaseAndNullify!(_);

	private SSAO ssao ~ delete _;

	private float delta;
	private bool afterScreenshot;
	
	[Tracy.Profile]
	public this() {
		mainColorI = attachments.CreateColor("Main Color");
		mainNormalI = attachments.CreateColor("Main Normal", .RGBA16);
		mainDepthI = attachments.CreateDepth("Main Depth");

		Input.keyEvent.Add(new => OnKey, -10);
	}

	private bool OnKey(Key key, int scancode, InputAction action) {
		if (action != .Press) return false;

		if (key == .Escape) {
			if (me.Screen != null) me.Screen = null;
			else me.window.MouseHidden = !me.window.MouseHidden;

			return true;
		}

		return false;
	}

	public void Tick() {
		me.lightmapManager.Tick();
	}
	
	[Tracy.Profile]
	public void Render(CommandBuffer cmds, GpuImage target, float delta) {
		this.delta = delta;

		FrameUniforms.Update();
		me.lightmapManager.Update(delta);

		if (me.options.ao.HasSSAO && ssao == null) ssao = new .(attachments);

		attachments.Resize(target.Size);

		cmds.Begin();

		Color clearColor = me.world != null ? me.world.GetClearColor(me.camera, me.tickCounter.tickDelta) : .(200, 200, 200, 255);
		bool world = me.world != null && me.worldRenderer != null;

		if (world) {
			SetupWorldRendering();

			{
				// Main Pre
				using (RenderPass pass = Gfx.RenderPasses.New(cmds, "Main - Pre")
					.Depth(MainDepth, 1)
					.Color(MainColor, clearColor)
					.Begin())
				{
					pass.SetViewport(target.Size, true, true);
					RenderMainPre(pass);
				}
			}
			{
				// Main
				using (RenderPass pass = Gfx.RenderPasses.New(cmds, "Main")
					.Depth(MainDepth)
					.Color(MainColor)
					.Color(MainNormal, .ZERO)
					.Begin())
				{
					pass.SetViewport(target.Size, true, true);
					RenderMain(pass);
				}
			}
			{
				// Main Post
				using (RenderPass pass = Gfx.RenderPasses.New(cmds, "Main - Post")
					.Depth(MainDepth)
					.Color(MainColor)
					.Begin())
				{
					pass.SetViewport(target.Size, true, true);
					RenderMainPost(pass);
				}
			}

			if (me.options.ao.HasSSAO) {
				// SSAO
				ssao.Render(cmds);
			}

			if (me.options.aa.enabled) {
				// SMAA
				if (smaaEdgesI == -1) {
					smaaEdgesI = attachments.CreateColor("SMAA - Edges", .RG8);
					smaaBlendI = attachments.CreateColor("SMAA - Blend");

					smaaArea = Gfxa.CreateImage("SMAA_AreaTex.png");
					smaaSearch = Gfxa.CreateImage("SMAA_SearchTex.png");
				}

				// SMAA - Edge Detection
				using (RenderPass pass = Gfx.RenderPasses.New(cmds, "SMAA - Edge Detection")
					.Color(SmaaEdges, .ZERO)
					.Begin())
				{
					pass.SetViewport(target.Size, true, true);
					RenderSmaaEdgeDetection(pass);
				}

				// SMAA - Blending
				using (RenderPass pass = Gfx.RenderPasses.New(cmds, "SMAA - Blending")
					.Color(SmaaBlend, .ZERO)
					.Begin())
				{
					pass.SetViewport(target.Size, true, true);
					RenderSmaaBlending(pass);
				}
			}

			{
				// Post
				using (RenderPass pass = Gfx.RenderPasses.New(cmds, "Post")
					.Color(target, .ZERO)
					.Begin())
				{
					pass.SetViewport(target.Size, true, true);
					RenderPost(pass);
				}
			}
		}

		// 2D
		if (!Screenshots.rendering || Screenshots.options.includeGui) {
			Color? clear = null;
			if (!world) clear = clearColor;

			using (RenderPass pass = Gfx.RenderPasses.New(cmds, "2D")
				.Color(target, clear)
				.Begin())
			{
				pass.SetViewport(target.Size, true, true);
				Render2D(pass);
			}
		}

		cmds.End();
	}

	[Tracy.Profile]
	private void SetupWorldRendering() {
		if (me.player != null/* && me.player.gamemode == .Spectator*/) {
			Vec3d pos = me.player.lastPos.Lerp(me.tickCounter.tickDelta, me.player.pos);
			me.camera.pos = .((.) (pos.x), (.) pos.y + 1.62f, (.) (pos.z));
			me.camera.yaw = me.player.yaw;
			me.camera.pitch = me.player.pitch;
		}
		/*else {
			if (!Input.capturingCharacters) me.camera.FlightMovement(delta);
		}*/

		me.camera.fov = me.options.fov;
		me.camera.Update(me.options.renderDistance * Section.SIZE * 4);
	}
	
	[Tracy.Profile]
	private void RenderMainPre(RenderPass pass) {
		me.worldRenderer.RenderPre(pass, me.tickCounter.tickDelta, delta);
	}
	
	[Tracy.Profile]
	private void RenderMain(RenderPass pass) {
		me.worldRenderer.Render(pass, me.tickCounter.tickDelta, delta);
	}
	
	[Tracy.Profile]
	private void RenderMainPost(RenderPass pass) {
		me.worldRenderer.RenderPost(pass, me.tickCounter.tickDelta, delta);
	}
	
	[Tracy.Profile]
	private void RenderSmaaEdgeDetection(RenderPass pass) {
		pass.Bind(Gfxa.SMAA_EDGE_DETECTION_PIPELINE);
		pass.Bind(0, FrameUniforms.Descriptor);
		pass.Bind(1, MainColorDescriptor);

		MeshBuilder mb = scope .();

		mb.Quad(
			mb.Vertex<PostVertex>(.(.(-1, -1), .(0, 1))),
			mb.Vertex<PostVertex>(.(.(-1, 1), .(0, 0))),
			mb.Vertex<PostVertex>(.(.(1, 1), .(1, 0))),
			mb.Vertex<PostVertex>(.(.(1, -1), .(1, 1)))
		);

		pass.Draw(mb.End());
	}
	
	[Tracy.Profile]
	private void RenderSmaaBlending(RenderPass pass) {
		pass.Bind(Gfxa.SMAA_BLENDING_PIPELINE);
		pass.Bind(0, FrameUniforms.Descriptor);
		pass.Bind(1, .SampledImage(SmaaEdges, Gfxa.LINEAR_SAMPLER));
		pass.Bind(2, .SampledImage(smaaArea, Gfxa.LINEAR_SAMPLER));
		pass.Bind(3, .SampledImage(smaaSearch, Gfxa.LINEAR_SAMPLER));

		MeshBuilder mb = scope .();

		mb.Quad(
			mb.Vertex<PostVertex>(.(.(-1, -1), .(0, 1))),
			mb.Vertex<PostVertex>(.(.(-1, 1), .(0, 0))),
			mb.Vertex<PostVertex>(.(.(1, 1), .(1, 0))),
			mb.Vertex<PostVertex>(.(.(1, -1), .(1, 1)))
		);

		pass.Draw(mb.End());
	}
	
	[Tracy.Profile]
	private void RenderPost(RenderPass pass) {
		pass.Bind(Gfxa.POST_PIPELINE);
		pass.Bind(0, FrameUniforms.Descriptor);
		pass.Bind(1, MainColorDescriptor);

		if (me.options.ao.HasSSAO) pass.Bind(2, ssao.Descriptor);
		else pass.Bind(2, Gfxa.PIXEL_DESCRIPTOR);

		if (me.options.aa.enabled) pass.Bind(3, .SampledImage(SmaaBlend, Gfxa.LINEAR_SAMPLER));

		MeshBuilder mb = scope .();

		mb.Quad(
			mb.Vertex<PostVertex>(.(.(-1, -1), .(0, 1))),
			mb.Vertex<PostVertex>(.(.(-1, 1), .(0, 0))),
			mb.Vertex<PostVertex>(.(.(1, 1), .(1, 0))),
			mb.Vertex<PostVertex>(.(.(1, -1), .(1, 1)))
		);

		pass.Draw(mb.End());
	}
	
	[Tracy.Profile]
	private void Render2D(RenderPass pass) {
		if (ImGuiCacti.NewFrame()) {
			if (me.world != null && me.player != null) me.hud.Render(pass, delta);

			me.Screen?.Render();
		}
	}
}

class Attachments {
	private append List<GpuImage> images = .();

	public ~this() {
		for (GpuImage image in images) {
			image.Release();
		}
	}

	[Tracy.Profile]
	public void Resize(Vec2i size) {
		for (var image in ref images) {
			Gfx.Images.Resize(ref image, size);
		}
	}

	public GpuImage Get(int index) {
		return images[index];
	}

	public int CreateColor(StringView name, ImageFormat format = .BGRA) {
		GpuImage image = Gfx.Images.Create(name, format, .ColorAttachment, .(1280, 720));

		images.Add(image);
		return images.Count - 1;
	}

	public int CreateDepth(StringView name) {
		GpuImage image = Gfx.Images.Create(name, .Depth, .DepthAttachment, .(1280, 720));

		images.Add(image);
		return images.Count - 1;
	}
}