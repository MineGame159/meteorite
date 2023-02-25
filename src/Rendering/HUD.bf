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
		private GpuImage widgetsImage ~ ReleaseAndNullify!(_);

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
			widgetsImage = Gfxa.CreateImage("gui/widgets.png");
		}
		
		[Tracy.Profile]
		public void Render(RenderPass pass, float delta) {
			alloc.FreeAll();

			if (me.world != null && me.worldRenderer != null) {
				RenderHotbar(pass);
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

			Vec3i posI = (.) me.player.pos;
			Biome biome = me.world.GetBiome(posI.x, posI.y, posI.z);
			String biomeName = scope .("Unknown");

			if (biome != null) {
				biomeName.Clear();

				String str = scope .(biome.Key);
				str.Replace(':', '.');

				I18N.Translate(scope $"biome.{str}", biomeName);
			}

			ImGui.Text("Pos: {:0.0} {:0.0} {:0.0}", me.camera.pos.x, me.camera.pos.y, me.camera.pos.z);
			ImGui.Text("Chunk: {} {}", posI.x >> 4, posI.z >> 4);
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
		private void RenderHotbar(RenderPass pass) {
			// Constants
			const Vec2f HOTBAR_SIZE = .(182, 22);
			const Vec2f SELECTED_SIZE = .(24, 24);

			const Vec2f XP_BAR_SIZE = .(182, 5);
			const Vec2f ICON_SIZE = .(9, 9);

			// Prepare widgets texture
			pass.Bind(Gfxa.TEX_QUADS_PIPELINE);
			pass.Bind(0, .SampledImage(widgetsImage, Gfxa.NEAREST_SAMPLER));

			Mat4 pc = me.camera.proj2d;	
			pass.SetPushConstants(pc);

			MeshBuilder mb = scope .();

			// Hotbar
			Vec2f pos = .(me.window.Width / 4 - HOTBAR_SIZE.x / 2, 0);
			Quad(mb, pos, HOTBAR_SIZE, .ZERO, HOTBAR_SIZE / widgetsImage.Size.ToFloat);

			// Selected slot
			Quad(mb, .(pos.x - 1 + me.player.inventory.selectedSlot * 20, pos.y - 1), SELECTED_SIZE, .(0, 22) / widgetsImage.Size.ToFloat, (.(0, 22) + SELECTED_SIZE) / widgetsImage.Size.ToFloat);

			// Render widgets texture
			pass.Draw(mb.End());

			if (me.player.gamemode == .Survival || me.player.gamemode == .Adventure) {
				// Prepare icons texture
				pass.Bind(0, .SampledImage(iconsImage, Gfxa.NEAREST_SAMPLER));
	
				mb = scope .();
	
				// XP
				Quad(mb, pos + .(0, HOTBAR_SIZE.y + 2), XP_BAR_SIZE, .(0, 64) / iconsImage.Size.ToFloat, (.(0, 64) + XP_BAR_SIZE) / iconsImage.Size.ToFloat);
				
				float xpProgress = me.player.xpProgress * XP_BAR_SIZE.x;
				Quad(mb, pos + .(0, HOTBAR_SIZE.y + 2), .(xpProgress, XP_BAR_SIZE.y), .(0, 69) / iconsImage.Size.ToFloat, (.(0, 69) + .(xpProgress, XP_BAR_SIZE.y)) / iconsImage.Size.ToFloat);
	
				// Health
				int health = (.) me.player.health;
	
				for (int i < 10) {
					Quad(mb, pos + .((ICON_SIZE.x - 1) * i, HOTBAR_SIZE.y + XP_BAR_SIZE.y + 3), ICON_SIZE, .(16, 0) / iconsImage.Size.ToFloat, (.(16, 0) + ICON_SIZE) / iconsImage.Size.ToFloat);
				}
	
				for (int i < health / 2) {
					Quad(mb, pos + .((ICON_SIZE.x - 1) * i, HOTBAR_SIZE.y + XP_BAR_SIZE.y + 3), ICON_SIZE, .(52, 0) / iconsImage.Size.ToFloat, (.(52, 0) + ICON_SIZE) / iconsImage.Size.ToFloat);
				}
				
				if (health % 2 != 0) {
					Quad(mb, pos + .((ICON_SIZE.x - 1) * (health / 2), HOTBAR_SIZE.y + XP_BAR_SIZE.y + 3), ICON_SIZE, .(61, 0) / iconsImage.Size.ToFloat, (.(61, 0) + ICON_SIZE) / iconsImage.Size.ToFloat);
				}
	
				// Food
				float foodWidth = (ICON_SIZE.x - 1) * 10 + 1;
				Vec2f foodPos = .(pos.x + HOTBAR_SIZE.x - foodWidth, pos.y);
				int food = me.player.food;
	
				for (int i < 10) {
					Quad(mb, foodPos + .((ICON_SIZE.x - 1) * i, HOTBAR_SIZE.y + XP_BAR_SIZE.y + 3), ICON_SIZE, .(16, 27) / iconsImage.Size.ToFloat, (.(16, 27) + ICON_SIZE) / iconsImage.Size.ToFloat);
				}
	
				for (int i < food / 2) {
					Quad(mb, foodPos + .(foodWidth - (ICON_SIZE.x - 1) * (i + 1) - 1, HOTBAR_SIZE.y + XP_BAR_SIZE.y + 3), ICON_SIZE, .(52, 27) / iconsImage.Size.ToFloat, (.(52, 27) + ICON_SIZE) / iconsImage.Size.ToFloat);
				}
	
				if (food % 2 != 0) {
					Quad(mb, foodPos + .(foodWidth - (ICON_SIZE.x - 1) * (food / 2 + 1) - 1, HOTBAR_SIZE.y + XP_BAR_SIZE.y + 3), ICON_SIZE, .(61, 27) / iconsImage.Size.ToFloat, (.(61, 27) + ICON_SIZE) / iconsImage.Size.ToFloat);
				}
	
				// Render icons texture
				pass.Draw(mb.End());
	
				// Render XP level
				me.textRenderer.Begin();
	
				String xpLevelStr = me.player.xpLevel.ToString(.. scope .());
				Vec2f xpLevelPos = .(pos.x + HOTBAR_SIZE.x / 2 - me.textRenderer.GetWidth(xpLevelStr) / 2 + 1, HOTBAR_SIZE.y + 2);
	
				me.textRenderer.Render(xpLevelPos.x + 1, xpLevelPos.y, xpLevelStr, .BLACK, false);
				me.textRenderer.Render(xpLevelPos.x - 1, xpLevelPos.y, xpLevelStr, .BLACK, false);
				me.textRenderer.Render(xpLevelPos.x, xpLevelPos.y + 1, xpLevelStr, .BLACK, false);
				me.textRenderer.Render(xpLevelPos.x, xpLevelPos.y - 1, xpLevelStr, .BLACK, false);
	
				me.textRenderer.Render(xpLevelPos.x, xpLevelPos.y, xpLevelStr, .(128, 255, 32), false);
	
				pass.Bind(0, me.textRenderer.Descriptor);
				me.textRenderer.End(pass);
			}
		}

		[Tracy.Profile]
		private void RenderCrosshair(RenderPass pass) {
			pass.Bind(crosshairPipeline);
			pass.Bind(0, .SampledImage(iconsImage, Gfxa.NEAREST_SAMPLER));

			Mat4 pc = me.camera.proj2d;
			pass.SetPushConstants(pc);

			MeshBuilder mb = scope .();

			float s1 = 15 / 2f;
			float s2 = 15 / 2f;

			float x = (me.window.Width - s1) / 4f;
			float y = (me.window.Height - s2) / 4f;

			float u = 15f / iconsImage.GetWidth();
			float v = 15f / iconsImage.GetHeight();

			Quad(mb, .(x, y), .(s1, s2), .ZERO, .(u, v), true);

			pass.Draw(mb.End());
		}

		private void Quad(MeshBuilder mb, Vec2f pos, Vec2f size, Vec2f uv1, Vec2f uv2, bool center = false) {
			var uv1, uv2;

			Color color = .WHITE;

			if (center) {
				mb.Quad(
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x - size.x, pos.y - size.y), .(uv1.x, uv2.y), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x - size.x, pos.y + size.y), .(uv1.x, uv1.y), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x + size.x, pos.y + size.y), .(uv2.x, uv1.y), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x + size.x, pos.y - size.y), .(uv2.x, uv2.y), color))
				);
			}
			else {
				mb.Quad(
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x, pos.y), .(uv1.x, uv2.y), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x, pos.y + size.y), .(uv1.x, uv1.y), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x + size.x, pos.y + size.y), .(uv2.x, uv1.y), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(pos.x + size.x, pos.y), .(uv2.x , uv2.y), color))
				);
			}
		}
	}
}