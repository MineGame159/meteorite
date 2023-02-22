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

		private Pipeline crosshairPipeline ~ ReleaseAndNullify!(_);
		private GpuImage iconsImage ~ ReleaseAndNullify!(_);

		private SimpleBumpAllocator alloc = new .() ~ delete _;

		private Average<60> fps = new .() ~ delete _;
		private Average<60> frameTime = new .() ~ delete _;
		private Average<60> gpuFrameTime = new .() ~ delete _;
		private double lastTime;

		private char8*[?] aos = .("None", "Vanilla", "SSAO", "Both");

		private bool debug = false;

		public this() {
			crosshairPipeline = Gfx.Pipelines.Create(scope PipelineInfo("Crosshair")
				.VertexFormat(Pos2DUVColorVertex.FORMAT)
				.Shader(.File(Gfxa.POS_TEX_COLOR_VERT), .File(Gfxa.POS_TEX_COLOR_FRAG))
				.Targets(
					.(.BGRA, .Enabled(
						.(.Add, .OneMinusDstColor, .OneMinusSrcColor),
						.(.Add, .One, .Zero)
					))
				)
			);

			iconsImage = Gfxa.CreateImage("gui/icons.png");
		}
		
		[Tracy.Profile]
		public void Render(RenderPass pass, float delta) {
			alloc.FreeAll();

			if (me.world != null && me.worldRenderer != null) {
				RenderCrosshair(pass);
				chat.Render(pass, delta);
			}

			double time = Glfw.GetTime();
			double deltaTime = time - lastTime;
			lastTime = time;

			fps.Add(1.0 / deltaTime);
			frameTime.Add(me.lastFrameTime.TotalMilliseconds);
			gpuFrameTime.Add(Gfx.CommandBuffers.TotalDuration.TotalMilliseconds);

			ImGui.Begin("Meteorite", null, .AlwaysAutoResize);
			ImGui.Text("FPS: {:0}", fps.Get());

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

				String str = scope .(biome.Key);
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
				I18N.Translate(scope $"block.minecraft.{blockState.block.Key.Path}", blockName);

				ImGui.Text("Selection: {} ({}, {}, {})", blockName, pos.x, pos.y, pos.z);
			}
			else ImGui.Text("Selection:");
			ImGui.Text("Speed: {:0.#}", me.player.Speed);

			ImGui.End();

			// Debug

			if (!Input.capturingCharacters && Input.IsKeyReleased(.G)) {
				debug = !debug;
			}

			if (debug) {
				RenderDebug();
			}
		}

		private void RenderDebug() {
			ImGui.SetNextWindowSizeConstraints(.(200, 0), .(float.MaxValue, float.MaxValue));
			ImGui.Begin("Debug", &debug, .AlwaysAutoResize);

			if (ImGui.CollapsingHeader("Basic")) {
				using (ImGuiTextList list = .(alloc)) {
					list.Text("FPS:", scope $"{fps.Get():0}");
					list.Separator();

					list.Text("CPU Frame:", scope $"{frameTime.Get():0.000} ms");
					list.Text("CPU Memory:", scope $"{Utils.UsedMemory} MB");
					list.Separator();

					list.Text("GPU Frame:", scope $"{gpuFrameTime.Get():0.000} ms");
					list.Text("GPU Memory:", scope $"{Gfx.UsedMemory / (1024 * 1024)} MB");
				}
			}

			if (ImGui.CollapsingHeader("Graphics object count")) {
				using (ImGuiTextList list = .(alloc)) {
					list.Text("Buffers:", Gfx.Buffers.Count);
					list.Text("Images:", Gfx.Images.Count);
					list.Text("Samplers:", Gfx.Samplers.Count);
					list.Text("Shaders:", Gfx.Shaders.Count);
					list.Separator();

					list.Text("Descriptor Sets:", scope $"{Gfx.DescriptorSets.Count} / {Gfx.DescriptorSetLayouts.Count}");
					list.Text("Pipelines:", scope $"{Gfx.Pipelines.Count} / {Gfx.PipelineLayouts.Count}");
					list.Separator();

					list.Text("Framebuffers:", Gfx.RenderPasses.FramebufferCount);
					list.Text("Render Passes:", Gfx.RenderPasses.Count);
				}
			}

			if (ImGui.CollapsingHeader("Render passes")) {
				using (ImGuiTextList list = .(alloc)) {
					for (let entry in Gfx.RenderPasses.DurationEntries) {
						list.Text(entry.name, scope $"{entry.duration.TotalMilliseconds:0.000} ms");
					}
				}
			}

			ImGui.End();
		}

		[Tracy.Profile]
		private void RenderCrosshair(RenderPass pass) {
			pass.Bind(crosshairPipeline);
			pass.Bind(0, .SampledImage(iconsImage, Gfxa.NEAREST_SAMPLER));

			Mat4 pc = me.camera.proj2d;
			pass.SetPushConstants(pc);

			Color color = .WHITE;
			MeshBuilder mb = scope .();

			float s1 = 15 / 2f;
			float s2 = 15 / 2f;

			float x = (me.window.Width - s1) / 4f;
			float y = (me.window.Height - s2) / 4f;

			float u = 15f / iconsImage.GetWidth();
			float v = 15f / iconsImage.GetHeight();

			mb.Quad(
				mb.Vertex<Pos2DUVColorVertex>(.(.(x - s1, y - s2), .(0, 0), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x - s1, y + s2), .(0, v), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + s1, y + s2), .(u, v), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + s1, y - s2), .(u, 0), color))
			);

			pass.Draw(mb.End());
		}
	}
}