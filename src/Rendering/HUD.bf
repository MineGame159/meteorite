using System;

using Cacti;
using Cacti.Graphics;
using ImGui;
using GLFW;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Meteorite;

class HudRenderer {
	private Meteorite me = .INSTANCE;

	public ChatRenderer chat = new .() ~ delete _;

	private Pipeline crosshairPipeline ~ ReleaseAndNullify!(_);

	private Average<60> fps = new .() ~ delete _;
	private Average<60> frameTime = new .() ~ delete _;
	private Average<60> gpuFrameTime = new .() ~ delete _;
	private double lastTime;

	private char8*[?] aos = .("None", "Vanilla", "SSAO", "Both");

	private bool debug = false;
	
	[Tracy.Profile]
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
	}
	
	[Tracy.Profile]
	public void Render(RenderPass pass, float delta) {
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
			using (ImGuiTextList list = .()) {
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
			using (ImGuiTextList list = .()) {
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
			using (ImGuiTextList list = .()) {
				for (let entry in Gfx.RenderPasses.DurationEntries) {
					list.Text(entry.name, scope $"{entry.duration.TotalMilliseconds:0.000} ms");
				}
			}
		}

		ImGui.End();
	}

	[Tracy.Profile]
	private void RenderHotbar(RenderPass pass) {
		// Prepare widgets texture
		pass.Bind(Gfxa.TEX_QUADS_PIPELINE);
		pass.Bind(0, me.textures.GetDescriptor("gui/widgets.png"));

		Mat4 pc = me.camera.proj2d;	
		pass.SetPushConstants(pc);

		MeshBuilder mb = scope .();

		// Hotbar
		Vec2f pos = .(me.window.Width / 4 - WidgetsAtlas.HOTBAR.size.x / 2, 0);
		Quad(mb, pos, WidgetsAtlas.HOTBAR);

		// Selected slot
		Quad(mb, .(pos.x - 1 + me.player.inventory.selectedSlot * 20, pos.y - 1), WidgetsAtlas.SELECTED_SLOT);

		// Render widgets texture
		pass.Draw(mb.End());

		if (me.player.gamemode == .Survival || me.player.gamemode == .Adventure) {
			// Prepare icons texture
			pass.Bind(0, me.textures.GetDescriptor("gui/icons.png"));

			mb = scope .();

			// XP
			pos.y += WidgetsAtlas.HOTBAR.size.y + 2;
			Quad(mb, pos, IconsAtlas.XP_BAR_BG);
			
			float xpProgress = me.player.xpProgress * IconsAtlas.XP_BAR_BG.size.x;
			Quad(mb, pos, .(xpProgress, IconsAtlas.XP_BAR_FG.size.y), IconsAtlas.XP_BAR_FG.uv1, .(IconsAtlas.XP_BAR_FG.uv1.x + (IconsAtlas.XP_BAR_FG.uv2.x - IconsAtlas.XP_BAR_FG.uv1.x) * me.player.xpProgress, IconsAtlas.XP_BAR_FG.uv2.y));

			// Health
			pos.y += IconsAtlas.XP_BAR_BG.size.y + 1;
			int health = (.) me.player.health;

			for (int i < 10) {
				Quad(mb, pos + .((IconsAtlas.HEART_BG.size.x - 1) * i, 0), IconsAtlas.HEART_BG);
			}

			for (int i < health / 2) {
				Quad(mb, pos + .((IconsAtlas.HEART_BG.size.x - 1) * i, 0), IconsAtlas.HEART_FG);
			}
			
			if (health % 2 != 0) {
				Quad(mb, pos + .((IconsAtlas.HEART_BG.size.x - 1) * (health / 2), 0), IconsAtlas.HEART_FG_HALF);
			}

			// Food
			float foodWidth = (IconsAtlas.FOOD_BG.size.x - 1) * 10 + 1;
			Vec2f foodPos = .(pos.x + WidgetsAtlas.HOTBAR.size.x - foodWidth, pos.y);
			int food = me.player.food;

			for (int i < 10) {
				Quad(mb, foodPos + .((IconsAtlas.FOOD_BG.size.x - 1) * i, 0), IconsAtlas.FOOD_BG);
			}

			for (int i < food / 2) {
				Quad(mb, foodPos + .(foodWidth - (IconsAtlas.FOOD_BG.size.x - 1) * (i + 1) - 1, 0), IconsAtlas.FOOD_FG);
			}

			if (food % 2 != 0) {
				Quad(mb, foodPos + .(foodWidth - (IconsAtlas.FOOD_BG.size.x - 1) * (food / 2 + 1) - 1, 0), IconsAtlas.FOOD_FG_HALF);
			}

			// Render icons texture
			pass.Draw(mb.End());

			// Render XP level
			me.textRenderer.Begin();

			String xpLevelStr = me.player.xpLevel.ToString(.. scope .());
			Vec2f xpLevelPos = .(pos.x + WidgetsAtlas.HOTBAR.size.x / 2 - me.textRenderer.GetWidth(xpLevelStr) / 2 + 1, WidgetsAtlas.HOTBAR.size.y + 2);

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
		pass.Bind(0, me.textures.GetDescriptor("gui/icons.png"));

		Mat4 pc = me.camera.proj2d;
		pass.SetPushConstants(pc);

		MeshBuilder mb = scope .();

		Vec2f size = (.) IconsAtlas.CROSSHAIR.size / 2;
		Vec2f pos = ((.) me.window.size - size) / 4;
		
		Quad(mb, pos, size, IconsAtlas.CROSSHAIR, true);

		pass.Draw(mb.End());
	}

	private void Quad(MeshBuilder mb, Vec2f pos, Vec2f size, Vec2f uv1, Vec2f uv2, bool center = false) {
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

	private void Quad(MeshBuilder mb, Vec2f pos, Vec2f size, TextureRegion region, bool center = false) => Quad(mb, pos, size, region.uv1, region.uv2, center);

	private void Quad(MeshBuilder mb, Vec2f pos, TextureRegion region) => Quad(mb, pos, (.) region.size, region);

	static class IconsAtlas {
		public const Vec2i SIZE = .(256, 256);
		
		public static TextureRegion CROSSHAIR = Get(0, 0, 16, 16);

		public static TextureRegion XP_BAR_BG = Get(0, 64, 182, 5);
		public static TextureRegion XP_BAR_FG = Get(0, 69, 182, 5);

		public static TextureRegion HEART_BG = Get(16, 0, 9, 9);
		public static TextureRegion HEART_FG = Get(52, 0, 9, 9);
		public static TextureRegion HEART_FG_HALF = Get(61, 0, 9, 9);

		public static TextureRegion FOOD_BG = Get(16, 27, 9, 9);
		public static TextureRegion FOOD_FG = Get(52, 27, 9, 9);
		public static TextureRegion FOOD_FG_HALF = Get(61, 27, 9, 9);

		private static TextureRegion Get(int x, int y, int width, int height) => .(.(x, y), .(width, height), SIZE);
	}

	static class WidgetsAtlas {
		public const Vec2i SIZE = .(256, 256);

		public static TextureRegion HOTBAR = Get(0, 0, 182, 22);
		public static TextureRegion SELECTED_SLOT = Get(0, 22, 24, 24);

		private static TextureRegion Get(int x, int y, int width, int height) => .(.(x, y), .(width, height), SIZE);
	}
}