using System;

using ImGui;
using GLFW;

namespace Meteorite {
	class HudRenderer {
		private Meteorite me = .INSTANCE;

		public ChatRenderer chat = new .() ~ delete _;

		public void Render(RenderPass pass, float delta) {
			if (me.world != null && me.worldRenderer != null) {
				Gfxa.TEX_QUADS_PIPELINE.Bind(pass);
				Gfxa.PIXEL_BIND_GRUP.Bind(pass);
	
				Mat4 pc = me.camera.proj2d;
				pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &pc);

				RenderCrosshair(pass);
				chat.Render(pass, delta);
			}

			ImGui.Begin("Meteorite", null, .AlwaysAutoResize);
			ImGui.Text("Frame: {:0.000} ms", (Glfw.GetTime() - Program.FRAME_START) * 1000);
			ImGui.Text("Memory: {} MB", Utils.GetUsedMemory());
			ImGui.Text("GPU Memory: {} MB", Gfx.ALLOCATED / 1024 / 1024);
			ImGui.Separator();

			if (me.world != null && me.worldRenderer != null) {
				ImGui.Text("Chunks: {} / {} (U: {})", me.worldRenderer.renderedChunks, me.world.ChunkCount, me.worldRenderer.chunkUpdates.Get());
				ImGui.Text("Entities: {} (B: {})", me.world.EntityCount, me.world.BlockEntityCount);
			}
			ImGui.Text("Pos: {:0} {:0} {:0}", me.camera.pos.x, me.camera.pos.y, me.camera.pos.z);
			ImGui.Separator();

			bool preAO = me.options.ao;
			ImGui.Checkbox("AO", &me.options.ao);
			if (me.options.ao != preAO) me.world.ReloadChunks();

			ImGui.Checkbox("Mipmaps", &me.options.mipmaps);
			ImGui.Checkbox("Sort Chunks", &me.options.sortChunks);
			ImGui.Checkbox("Chunk Boundaries", &me.options.chunkBoundaries);

			ImGui.PushItemWidth(150);
			ImGui.SliderFloat("FOV", &me.options.fov, 10, 170, "%.0f");
			ImGui.PopItemWidth();

			ImGui.End();
		}

		private void RenderCrosshair(RenderPass pass) {
			Color color = .(200, 200, 200);
			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass);

			float x = me.window.width / 4f;
			float y = me.window.height / 4f;

			float s1 = 6;
			float s2 = 1;

			mb.Quad(
				mb.Vec2(.(x - s1, y - s2)).Vec2(.()).Color(color).Next(),
				mb.Vec2(.(x - s1, y + s2)).Vec2(.()).Color(color).Next(),
				mb.Vec2(.(x + s1, y + s2)).Vec2(.()).Color(color).Next(),
				mb.Vec2(.(x + s1, y - s2)).Vec2(.()).Color(color).Next()
			);

			mb.Quad(
				mb.Vec2(.(x - s2, y - s1)).Vec2(.()).Color(color).Next(),
				mb.Vec2(.(x - s2, y + s1)).Vec2(.()).Color(color).Next(),
				mb.Vec2(.(x + s2, y + s1)).Vec2(.()).Color(color).Next(),
				mb.Vec2(.(x + s2, y - s1)).Vec2(.()).Color(color).Next()
			);

			mb.Finish();
		}
	}
}