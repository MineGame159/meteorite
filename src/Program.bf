using System;
using System.Threading;
using System.Collections;
using System.Diagnostics;
using GLFW;
using ImGui;
using Wgpu;

namespace Meteorite {
	class Program {
		public static bool AO = true;

		public static void Main() {
			Meteorite me = new .();

			bool mipmaps = true;
			bool sortChunks = true;
			bool chunkBoundaries = false;

			double lastTime = Glfw.GetTime();

			while (!me.window.ShouldClose) {
				double time = Glfw.GetTime();
				float delta = (.) (time - lastTime);
				lastTime = time;

				Input.[Friend]Update();
				me.window.PollEvents();

				if (me.window.minimized) {
					me.Render(mipmaps, sortChunks, chunkBoundaries, delta);
					Thread.Sleep(1);
					continue;
				}

				bool escaped = Screenshots.Update();

				Gfx.BeginFrame(me.world != null ? me.world.GetClearColor(me.camera, me.tickCounter.tickDelta) : .(200, 200, 200, 255));

				double start = Glfw.GetTime();

				if (me.connection == null) MainMenu.Render();
				else {
					if (!escaped && Input.IsKeyPressed(.Escape)) me.window.MouseHidden = !me.window.MouseHidden;
	
					me.Render(mipmaps, sortChunks, chunkBoundaries, delta);

					ImGui.Begin("Meteorite");
					ImGui.Text("Frame: {:0.000} ms", (Glfw.GetTime() - start) * 1000);
					ImGui.Text("Memory: {} MB", Utils.GetUsedMemory());
					ImGui.Text("GPU Memory: {} MB", Gfx.ALLOCATED / 1024 / 1024);
					ImGui.Separator();

					if (me.world != null) {
						ImGui.Text("Chunks: {} / {}", me.world.renderedChunks, me.world.ChunkCount);
						ImGui.Text("Entities: {}", me.world.EntityCount);
					}
					ImGui.Text("Pos: {:0} {:0} {:0}", me.camera.pos.x, me.camera.pos.y, me.camera.pos.z);
					ImGui.Separator();
	
					bool preAO = AO;
					ImGui.Checkbox("AO", &AO);
					if (AO != preAO) me.world.ReloadChunks();

					ImGui.Checkbox("Mipmaps", &mipmaps);
					ImGui.Checkbox("Sort Chunks", &sortChunks);
					ImGui.Checkbox("Chunk Boundaries", &chunkBoundaries);
					ImGui.End();

					Screenshots.Render();
				}

				Gfx.EndFrame();
			}

			delete Meteorite.INSTANCE;
		}
	}
}