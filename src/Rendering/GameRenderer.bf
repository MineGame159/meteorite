using System;
using System.Collections;

using Cacti;
using ImGui;

namespace Meteorite {
	class GameRenderer {
		private Meteorite me = .INSTANCE;

		private List<GpuImage> images = new .() ~ DeleteContainerAndItems!(_);

		public GpuImage mainColor, mainNormal;
		public GpuImage mainDepth;

		public DescriptorSet mainColorSet ~ delete _, mainNormalSet ~ delete _, mainDepthSet ~ delete _;

		private SSAO ssao ~ delete _;

		private float delta;
		private bool afterScreenshot;

		public this() {
			mainColor = ColorImage("Main Color");
			mainNormal = ColorImage("Main Normal", .RGBA16);
			mainDepth = DepthImage("Main Depth");

			mainColorSet = Gfx.DescriptorSets.Create(Gfxa.IMAGE_SET_LAYOUT, .SampledImage(mainColor, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.NEAREST_SAMPLER));
			mainNormalSet = Gfx.DescriptorSets.Create(Gfxa.IMAGE_SET_LAYOUT, .SampledImage(mainNormal, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.NEAREST_SAMPLER));
			mainDepthSet = Gfx.DescriptorSets.Create(Gfxa.IMAGE_SET_LAYOUT, .SampledImage(mainDepth, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.NEAREST_SAMPLER));

			Input.keyEvent.Add(new => OnKey, -10);
		}

		private bool OnKey(Key key, InputAction action) {
			if (action != .Press) return false;

			if (key == .Escape) {
				me.window.MouseHidden = !me.window.MouseHidden;
				return true;
			}

			return false;
		}

		public void Tick() {
			if (me.world != null && me.worldRenderer != null) me.worldRenderer.Tick();
		}

		public void Render(CommandBuffer cmds, GpuImage target, float delta) {
			this.delta = delta;

			//Screenshots.Update();
			FrameUniforms.Update();

			if (me.options.ao.HasSSAO && ssao == null) ssao = new .(ColorImage("SSAO", .R8));

			for (GpuImage image in images)
				image.Resize(target.size);

			//Begin();
			cmds.Begin();
			cmds.SetViewport(target.size, true, true);

			Color clearColor = me.world != null ? me.world.GetClearColor(me.camera, me.tickCounter.tickDelta) : .(200, 200, 200, 255);
			bool world = me.world != null && me.worldRenderer != null;

			if (world) {
				SetupWorldRendering();

				{
					// Main Pre
					cmds.BeginPass(.(mainDepth, 1), .(mainColor, clearColor));
					RenderMainPre(cmds);
					cmds.EndPass();
				}
				{
					// Main
					cmds.BeginPass(.(mainDepth, null), .(mainColor, null), .(mainNormal, .ZERO));
					RenderMain(cmds);
					cmds.EndPass();
				}
				{
					// Main Post
					cmds.BeginPass(.(mainDepth, null), .(mainColor, null));
					RenderMainPost(cmds);
					cmds.EndPass();
				}

				if (me.options.ao.HasSSAO) {
					// SSAO
					ssao.Render(cmds);
				}

				{
					// Post
					cmds.TransitionImage(mainColor, .Sample);
					if (ssao != null) ssao.Transition(cmds);

					cmds.BeginPass(null, .(target, .ZERO));
					RenderPost(cmds);
					cmds.EndPass();
				}
			}

			// 2D
			//if (!Screenshots.rendering || Screenshots.includeGui) {
				Color? clear = null;
				if (!world) clear = clearColor;

				cmds.BeginPass(null, .(target, clear));
				Render2D(cmds);
				cmds.EndPass();
			//}

			cmds.End();
			//End();
		}

		private void SetupWorldRendering() {
			if (me.player != null && me.player.gamemode == .Spectator) {
				Vec3d pos = me.player.pos.Lerp(me.tickCounter.tickDelta, me.player.lastPos);
				me.camera.pos = .((.) (pos.x + me.player.type.width / 2), (.) pos.y + 1.62f, (.) (pos.z + me.player.type.width / 2));
				me.camera.yaw = me.player.yaw;
				me.camera.pitch = me.player.pitch;
			}
			else {
				if (!Input.capturingCharacters) me.camera.FlightMovement(delta);
			}
			
			me.camera.Update(me.world.viewDistance * Section.SIZE * 4);
		}

		private void RenderMainPre(CommandBuffer cmds) {
			me.worldRenderer.RenderPre(cmds, me.tickCounter.tickDelta, delta);
		}

		private void RenderMain(CommandBuffer cmds) {
			me.worldRenderer.Render(cmds, me.tickCounter.tickDelta, delta);
		}

		private void RenderMainPost(CommandBuffer cmds) {
			me.worldRenderer.RenderPost(cmds, me.tickCounter.tickDelta, delta);
		}

		private void RenderPost(CommandBuffer cmds) {
			cmds.PushDebugGroup("Post");

			cmds.Bind(Gfxa.POST_PIPELINE);
			FrameUniforms.Bind(cmds);
			cmds.Bind(mainColorSet, 1);

			if (me.options.ao.HasSSAO) ssao.Bind(cmds, 2);
			else cmds.Bind(Gfxa.PIXEL_SET, 2);

			MeshBuilder mb = scope .();

			mb.Quad(
				mb.Vertex<PostVertex>(.(.(-1, -1), .(0, 1))),
				mb.Vertex<PostVertex>(.(.(-1, 1), .(0, 0))),
				mb.Vertex<PostVertex>(.(.(1, 1), .(1, 0))),
				mb.Vertex<PostVertex>(.(.(1, -1), .(1, 1)))
			);

			cmds.Draw(mb.End());

			cmds.PopDebugGroup();
		}

		private void Render2D(CommandBuffer cmds) {
			if (ImGuiCacti.NewFrame()) {
				cmds.PushDebugGroup("2D");

				if (me.connection == null) MainMenu.Render();
				else me.hud.Render(cmds, delta);

				cmds.PopDebugGroup();
			}
		}

		private GpuImage ColorImage(StringView name, ImageFormat format = .BGRA) {
			GpuImage image = Gfx.Images.Create(format, .ColorAttachment, .(1280, 720), name);
			images.Add(image);
			return image;
		}

		private GpuImage DepthImage(StringView name) {
			GpuImage image = Gfx.Images.Create(.Depth, .DepthAttachment, .(1280, 720), name);
			images.Add(image);
			return image;
		}

		/*private void Begin() {
			int screenWidth = me.window.width;
			int screenHeight = me.window.height;

			if (Screenshots.rendering) {
				output = Screenshots.texture.CreateView();

				screenWidth = Screenshots.width;
				screenHeight = Screenshots.height;
			}
			else output = Gfx.swapChain.GetCurrentTextureView();

			for (Texture texture in textures)
				texture.Resize(screenWidth, screenHeight);

			Wgpu.CommandEncoderDescriptor encoderDesc = .();
			encoder = Gfx.device.CreateCommandEncoder(&encoderDesc);
		}

		private void End() {
			if (afterScreenshot) {
				Screenshots.AfterRender(encoder);
			}

			Wgpu.CommandBufferDescriptor cbDesc = .();
			Wgpu.CommandBuffer cb = encoder.Finish(&cbDesc);
			Gfx.queue.Submit(1, &cb);

			if (!Screenshots.rendering) Gfx.swapChain.Present();
			output.Drop();

			if (afterScreenshot) {
				afterScreenshot = false;
				Screenshots.Save();
			}

			if (Screenshots.rendering) {
				afterScreenshot = true;
				Screenshots.rendering = false;
			}
		}*/
	}
}