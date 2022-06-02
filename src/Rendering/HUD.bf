using System;

using ImGui;
using GLFW;

namespace Meteorite {
	static class HUD {
		public static void Render() {
			Meteorite me = .INSTANCE;

			ImGui.Begin("Meteorite");
			ImGui.Text("Frame: {:0.000} ms", (Glfw.GetTime() - Program.FRAME_START) * 1000);
			ImGui.Text("Memory: {} MB", Utils.GetUsedMemory());
			ImGui.Text("GPU Memory: {} MB", Gfx.ALLOCATED / 1024 / 1024);
			ImGui.Separator();

			if (me.world != null) {
				ImGui.Text("Chunks: {} / {}", me.world.renderedChunks, me.world.ChunkCount);
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
			ImGui.End();
		}
	}
}