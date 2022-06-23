using System;
using System.Collections;

using Wgpu;
using ImGui;

namespace Meteorite {
	class GameRenderer {
		private Meteorite me = .INSTANCE;

		private List<Texture> textures = new .() ~ DeleteContainerAndItems!(_);
		private Wgpu.TextureView output;
		private Wgpu.CommandEncoder encoder;

		public Texture mainColor, mainNormal;
		public Texture mainDepth;

		private SSAO ssao ~ delete _;

		private float delta;
		private bool afterScreenshot;

		public this() {
			mainColor = ColorTexture();
			mainNormal = ColorTexture(.RGBA16Float);
			mainDepth = DepthTexture();

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

		public void Render(float delta) {
			this.delta = delta;

			Screenshots.Update();
			FrameUniforms.Update();

			if (me.options.ao.HasSSAO && ssao == null) ssao = new .(ColorTexture(.R8Unorm));

			Begin();

			Color clearColor = me.world != null ? me.world.GetClearColor(me.camera, me.tickCounter.tickDelta) : .(200, 200, 200, 255);
			bool world = me.world != null && me.worldRenderer != null;

			if (world) {
				SetupWorldRendering();

				{
					// Main Pre
					RenderPass pass = RenderPass.Begin(encoder)
						.Color(mainColor, clearColor)
						.Depth(mainDepth, 1)
						.Finish();
					
					RenderMainPre(pass);
					pass.End();
				}
				{
					// Main
					RenderPass pass = RenderPass.Begin(encoder)
						.Color(mainColor)
						.Color(mainNormal, .ZERO)
						.Depth(mainDepth)
						.Finish();
					
					RenderMain(pass);
					pass.End();
				}
				{
					// Main Post
					RenderPass pass = RenderPass.Begin(encoder)
						.Color(mainColor)
						.Depth(mainDepth)
						.Finish();
					
					RenderMainPost(pass);
					pass.End();
				}
				if (me.options.ao.HasSSAO) {
					// SSAO
					ssao.Render(encoder);
				}
				{
					// Post
					RenderPass pass = RenderPass.Begin(encoder)
						.Color(output, .(0, 0, 0, 0))
						.Finish();

					RenderPost(pass);
					pass.End();
				}
			}

			// 2D
			if (!Screenshots.rendering || Screenshots.includeGui) {
				Color? clear = null;
				if (!world) clear = clearColor;

				RenderPass pass = RenderPass.Begin(encoder)
					.Color(output, clear)
					.Finish();

				Render2D(pass);
				pass.End();
			}

			End();
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

		private void RenderMainPre(RenderPass pass) {
			me.worldRenderer.RenderPre(pass, me.tickCounter.tickDelta, delta);
		}

		private void RenderMain(RenderPass pass) {
			me.worldRenderer.Render(pass, me.tickCounter.tickDelta, delta);
		}

		private void RenderMainPost(RenderPass pass) {
			me.worldRenderer.RenderPost(pass, me.tickCounter.tickDelta, delta);
		}

		private void RenderPost(RenderPass pass) {
			pass.PushDebugGroup("Post");

			Gfxa.POST_PIPELINE.Bind(pass);
			FrameUniforms.Bind(pass);
			mainColor.Bind(pass, 1);

			if (me.options.ao.HasSSAO) ssao.Bind(pass, 2);
			else Gfxa.PIXEL_BIND_GRUP.Bind(pass, 2);

			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass);
			mb.Quad(
				mb.Vec2(.(-1, -1)).Vec2(.(0, 1)).Next(),
				mb.Vec2(.(-1, 1)).Vec2(.(0, 0)).Next(),
				mb.Vec2(.(1, 1)).Vec2(.(1, 0)).Next(),
				mb.Vec2(.(1, -1)).Vec2(.(1, 1)).Next()
			);
			mb.Finish();

			pass.PopDebugGroup();
		}

		private void Render2D(RenderPass pass) {
			pass.PushDebugGroup("2D");

			ImGuiImplWgpu.NewFrame();
			ImGuiImplGlfw.NewFrame();
			ImGui.NewFrame();

			if (me.connection == null) MainMenu.Render();
			else me.hud.Render(pass, delta);

			Screenshots.Render();

			ImGui.Render();
			ImGuiImplWgpu.RenderDrawData(ImGui.GetDrawData(), pass.[Friend]encoder);
			pass.PopDebugGroup();
		}

		private Texture ColorTexture(Wgpu.TextureFormat format = .BGRA8Unorm) {
			Texture texture = Gfx.CreateTexture(.RenderAttachment | .TextureBinding, 0, 0, 1, null, format, false, format == .BGRA8Unorm ? Gfxa.LINEAR_SAMPLER : Gfxa.NEAREST_SAMPLER);
			textures.Add(texture);
			return texture;
		}

		private Texture DepthTexture() {
			Texture texture = Gfx.CreateTexture(.RenderAttachment | .TextureBinding, 0, 0, 1, null, .Depth32Float, false);
			textures.Add(texture);
			return texture;
		}

		private void Begin() {
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
		}
	}
}