using System;
using System.Collections;

using Wgpu;
using ImGui;

namespace Meteorite {
	class GameRenderer {
		private Meteorite me = .INSTANCE;

		private RenderPass mainPass ~ delete _;
		private RenderPass _2dPass ~ delete _;

		private float delta;
		private bool afterScreenshot;

		public this() {
			mainPass = Gfx.NewRenderPass()
				.Callback(new => RenderMain)
				.Color(.Screen, .(0, 0, 0), true)
				.Depth(.Screen, 1)
				.Create();

			_2dPass = Gfx.NewRenderPass()
				.Callback(new => Render2D)
				.Color(mainPass)
				.Create();
		}

		public void Tick() {
			if (me.world != null && me.worldRenderer != null) me.worldRenderer.Tick();
		}

		public void Render(float delta) {
			this.delta = delta;

			List<RenderPass> passes = scope .();
			mainPass.SetClearColor(me.world != null ? me.world.GetClearColor(me.camera, me.tickCounter.tickDelta) : .(200, 200, 200, 255));

			bool escaped = Screenshots.Update();
			if (!escaped && Input.IsKeyPressed(.Escape)) me.window.MouseHidden = !me.window.MouseHidden;

			if (me.world != null && me.worldRenderer != null) {
				SetupWorldRendering();
				passes.Add(mainPass);
			}

			if (!Screenshots.rendering || Screenshots.includeGui) passes.Add(_2dPass);

			Render(passes);
		}

		private void SetupWorldRendering() {
			if (me.player != null && me.player.gamemode == .Spectator) {
				Vec3d pos = me.player.pos.Lerp(me.tickCounter.tickDelta, me.player.lastPos);
				me.camera.pos = .((.) (pos.x + me.player.type.width / 2), (.) pos.y + 1.62f, (.) (pos.z + me.player.type.width / 2));
				me.camera.yaw = me.player.yaw;
				me.camera.pitch = me.player.pitch;
			}
			else {
				me.camera.FlightMovement(delta);
			}
			
			me.camera.Update(me.world.viewDistance * Section.SIZE * 4);
		}

		private void RenderMain(RenderPass pass) {
			me.worldRenderer.Render(pass, me.tickCounter.tickDelta, delta);
		}

		private void Render2D(RenderPass pass) {
			pass.PushDebugGroup("2D");
			ImGuiImplWgpu.NewFrame();
			ImGuiImplGlfw.NewFrame();
			ImGui.NewFrame();

			if (me.connection == null) MainMenu.Render();
			else HUD.Render();

			Screenshots.Render();

			ImGui.Render();
			ImGuiImplWgpu.RenderDrawData(ImGui.GetDrawData(), pass);
			pass.PopDebugGroup();
		}

		private void Render(List<RenderPass> passes) {
			Wgpu.TextureView view;

			int screenWidth = me.window.width;
			int screenHeight = me.window.height;

			if (Screenshots.rendering) {
				view = Screenshots.texture.CreateView();

				screenWidth = Screenshots.width;
				screenHeight = Screenshots.height;
			}
			else view = Gfx.swapChain.GetCurrentTextureView();

			Wgpu.CommandEncoderDescriptor encoderDesc = .();
			Wgpu.CommandEncoder encoder = Gfx.device.CreateCommandEncoder(&encoderDesc);
			
			for (RenderPass pass in passes) pass.Render(encoder, view, screenWidth, screenHeight);
			for (RenderPass pass in passes) pass.AfterRender();

			if (afterScreenshot) {
				Screenshots.AfterRender(encoder);
			}

			Wgpu.CommandBufferDescriptor cbDesc = .();
			Wgpu.CommandBuffer cb = encoder.Finish(&cbDesc);
			Gfx.queue.Submit(1, &cb);

			if (!Screenshots.rendering) Gfx.swapChain.Present();
			view.Drop();

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