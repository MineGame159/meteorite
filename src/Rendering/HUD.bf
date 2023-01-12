using System;

using Cacti;
using ImGui;
using GLFW;

namespace Meteorite {
	class HudRenderer {
		private Meteorite me = .INSTANCE;

		public ChatRenderer chat = new .() ~ delete _;

		private char8*[?] aos = .("None", "Vanilla", "SSAO", "Both");

		public void Render(CommandBuffer cmds, float delta) {
			if (me.world != null && me.worldRenderer != null) {
				cmds.Bind(Gfxa.TEX_QUADS_PIPELINE);
				cmds.Bind(Gfxa.PIXEL_SET, 0);
	
				Mat4 pc = me.camera.proj2d;
				cmds.SetPushConstants(pc);

				RenderCrosshair(cmds);
				chat.Render(cmds, delta);
			}

			ImGui.Begin("Meteorite", null, .AlwaysAutoResize);
			ImGui.Text("Frame: {:0.000} ms", Meteorite.INSTANCE.lastFrameTime.TotalMilliseconds);
			ImGui.Text("Memory: {} MB", Utils.GetUsedMemory());
			//ImGui.Text("GPU Memory: {} MB", Gfx.ALLOCATED / 1024 / 1024);
			ImGui.Separator();

			if (me.world != null && me.worldRenderer != null) {
				ImGui.Text("Chunks: {} / {} (U: {})", me.worldRenderer.renderedChunks, me.world.ChunkCount, me.worldRenderer.chunkUpdates.Get());
				ImGui.Text("Entities: {} (B: {})", me.world.EntityCount, me.world.BlockEntityCount);
			}
			ImGui.Text("Pos: {:0} {:0} {:0}", me.camera.pos.x, me.camera.pos.y, me.camera.pos.z);
			ImGui.Separator();

			ImGui.Checkbox("Mipmaps", &me.options.mipmaps);
			ImGui.Checkbox("Sort Chunks", &me.options.sortChunks);
			ImGui.Checkbox("Chunk Boundaries", &me.options.chunkBoundaries);
			ImGui.PushItemWidth(150);
			ImGui.SliderFloat("FOV", &me.options.fov, 10, 170, "%.0f");
			ImGui.Separator();

			int32 ao = me.options.ao.Underlying;
			if (ImGui.Combo("AO", &ao, &aos, aos.Count)) {
				bool prevVanilla = me.options.ao.HasVanilla;
				bool prevSsao = me.options.ao.HasSSAO;

				me.options.ao = (.) ao;

				if (prevVanilla != me.options.ao.HasVanilla) me.world.ReloadChunks();
				if (prevSsao != me.options.ao.HasSSAO) {
					Gfxa.POST_PIPELINE.Reload();
					Meteorite.INSTANCE.gameRenderer.[Friend]ssao?.pipeline.Reload();
				}
			}
			if (ImGui.Checkbox("FXAA", &me.options.fxaa)) Gfxa.POST_PIPELINE.Reload();
			ImGui.PopItemWidth();

			ImGui.End();
		}

		private void RenderCrosshair(CommandBuffer cmds) {
			Color color = .(200, 200, 200);
			MeshBuilder mb = scope .();

			float x = me.window.Width / 4f;
			float y = me.window.Height / 4f;

			float s1 = 6;
			float s2 = 1;

			mb.Quad(
				mb.Vertex<Pos2DUVColorVertex>(.(.(x - s1, y - s2), .(), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x - s1, y + s2), .(), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + s1, y + s2), .(), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + s1, y - s2), .(), color))
			);

			mb.Quad(
				mb.Vertex<Pos2DUVColorVertex>(.(.(x - s2, y - s1), .(), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x - s2, y + s1), .(), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + s2, y + s1), .(), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + s2, y - s1), .(), color))
			);

			cmds.Draw(mb.End());
		}
	}
}