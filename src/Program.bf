using System;
using System.Collections;
using System.Diagnostics;
using GLFW;
using ImGui;
using Wgpu;

namespace Meteorite {
	class Program {
		public static bool AO = true;

		public static Camera camera;

		public static void Main() {
			Window window = scope Window();

			camera = scope Camera(window);
			camera.pos.y = 160;
			camera.yaw = 45;

			I18N.Load();
			Blocks.Register();
			BlockModelLoader.LoadModels();
			Biomes.Register();
			Biome.LoadColormaps();
			EntityTypes.Register();
			Buffers.CreateGlobalIndices();
			Gfxa.Init();

			RenderTickCounter tickCounter = scope .(20, 0);
			ClientConnection c = null;

			char8[16] username = "Meteorite";
			char8[32] ip = "localhost";
			char8[6] port = "25565";

			bool wireframe = false;
			bool mipmaps = true;
			bool chunkBoundaries = false;

			double lastTime = Glfw.GetTime();

			while (!window.ShouldClose) {
				double time = Glfw.GetTime();
				float delta = (.) (time - lastTime);
				lastTime = time;

				Input.[Friend]Update();
				window.PollEvents();

				Gfx.BeginFrame();

				double start = Glfw.GetTime();

				if (c == null) {
					ImGui.Begin("Menu");

					ImGui.InputText("Username", &username, username.Count);
					ImGui.InputText("IP", &ip, ip.Count);
					ImGui.InputText("Port", &port, port.Count);

					if (ImGui.Button("Connect", .(-1, 0))) {
						c = new .(.(&ip), int32.Parse(.(&port)));
						window.MouseHidden = true;
					}

					ImGui.End();
				}
				else {
					if (Input.IsKeyPressed(.Escape)) window.MouseHidden = !window.MouseHidden;
	
					camera.FlightMovement(delta);
					camera.Update();

					//glPolygonMode(GL_FRONT_AND_BACK, wireframe ? GL_LINE : GL_FILL);
					if (c.world != null) {
						int tickCount = tickCounter.BeginRenderTick();
						for (int i < Math.Min(10, tickCount)) c.world.Tick();

						c.world.Render(camera, tickCounter.tickDelta, mipmaps);
						if (chunkBoundaries) c.world.RenderChunkBoundaries(camera);
					}
	
					ImGui.Begin("Meteorite");
					ImGui.Text("Frame: {:0.000} ms", (Glfw.GetTime() - start) * 1000);
					ImGui.Text("Memory: {} MB", Utils.GetUsedMemory());
					if (c.world != null) {
						ImGui.Text("Chunks: {} / {}", c.world.renderedChunks, c.world.ChunkCount);
						ImGui.Text("Entities: {}", c.world.EntityCount);
					}
					ImGui.Text("Pos: {:0} {:0} {:0}", camera.pos.x, camera.pos.y, camera.pos.z);
					ImGui.Checkbox("Wireframe", &wireframe);
	
					bool preAO = AO;
					ImGui.Checkbox("AO", &AO);
					if (AO != preAO) c.world.ReloadChunks();

					ImGui.Checkbox("Mipmaps", &mipmaps);
					ImGui.Checkbox("Chunk Boundaries", &chunkBoundaries);
					ImGui.End();
				}

				Gfx.EndFrame();
			}

			Gfx.Shutdown();

			delete c;
		}
	}
}