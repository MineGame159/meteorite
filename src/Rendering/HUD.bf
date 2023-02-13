using System;

using Cacti;
using Cacti.Graphics;
using ImGui;
using GLFW;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Meteorite {
	class HudRenderer {
		private Meteorite me = .INSTANCE;

		public ChatRenderer chat = new .() ~ delete _;

		private Average<60> fps = new .() ~ delete _;
		private Average<60> frameTime = new .() ~ delete _;
		private Average<60> gpuFrameTime = new .() ~ delete _;
		private double lastTime;

		private char8*[?] aos = .("None", "Vanilla", "SSAO", "Both");
		
		[Tracy.Profile]
		public void Render(RenderPass pass, float delta) {
			if (me.world != null && me.worldRenderer != null) {
				pass.Bind(Gfxa.TEX_QUADS_PIPELINE);
				pass.Bind(0, Gfxa.PIXEL_DESCRIPTOR);
	
				Mat4 pc = me.camera.proj2d;
				pass.SetPushConstants(pc);

				RenderCrosshair(pass);
				chat.Render(pass, delta);
			}

			double time = Glfw.GetTime();
			double deltaTime = time - lastTime;
			lastTime = time;

			fps.Add(1.0 / deltaTime);
			frameTime.Add(me.lastFrameTime.TotalMilliseconds);
			gpuFrameTime.Add(Gfx.Queries.total.TotalMilliseconds);

			ImGui.Begin("Meteorite", null, .AlwaysAutoResize);
			ImGui.Text("FPS: {:0}", fps.Get());
			ImGui.Text("CPU: {:0.000} ms, GPU: {:0.000} ms", frameTime.Get(), gpuFrameTime.Get());
			ImGui.Text("CPU: {} MB, GPU: {} MB", Utils.UsedMemory, Gfx.UsedMemory / (1024 * 1024));

			ImGui.Separator();
			if (me.worldRenderer != null) {
				ImGui.Text("Chunks: {} / {}", me.worldRenderer.chunkRenderer.VisibleChunkCount, me.world.ChunkCount);
				ImGui.Text("Entities: {} (B: {})", me.world.EntityCount, me.world.BlockEntityCount);
			}
			ImGui.Separator();

			Biome biome = me.world.GetBiome(me.player.pos.IntX, me.player.pos.IntY, me.player.pos.IntZ);
			String biomeName = scope .("Unknown");

			if (biome != null) {
				biomeName.Clear();

				String str = scope .(biome.name);
				str.Replace(':', '.');

				I18N.Translate(scope $"biome.{str}", biomeName);
			}

			ImGui.Text("Pos: {:0.0} {:0.0} {:0.0}", me.camera.pos.x, me.camera.pos.y, me.camera.pos.z);
			ImGui.Text("Chunk: {} {}", me.player.pos.IntX >> 4, me.player.pos.IntZ >> 4);
			ImGui.Text("Biome: {}", biomeName);
			if (me.player.selection != null && !me.player.selection.missed) {
				Vec3i pos = me.player.selection.blockPos;
				BlockState blockState = me.world.GetBlock(me.player.selection.blockPos);

				String blockName = scope .();
				I18N.Translate(scope $"block.minecraft.{blockState.block.id}", blockName);

				ImGui.Text("Selection: {} ({}, {}, {})", blockName, pos.x, pos.y, pos.z);
			}
			else ImGui.Text("Selection:");
			ImGui.Text("Speed: {:0.#}", me.player.Speed);

			ImGui.End();
		}

		private void RenderCrosshair(RenderPass pass) {
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

			pass.Draw(mb.End());
		}
	}
}