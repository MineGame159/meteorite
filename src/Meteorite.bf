using System;
using System.IO;

namespace Meteorite {
	class Meteorite {
		public static Meteorite INSTANCE;

		public Options options ~ delete _;
		public Window window ~ delete _;
		public ResourceLoader resources ~ delete _;
		public TextureManager textures ~ delete _;

		public Camera camera ~ delete _;
		public RenderTickCounter tickCounter ~ delete _;

		public ClientConnection connection ~ delete _;
		public World world ~ delete _;

		public this() {
			INSTANCE = this;
			Directory.CreateDirectory("run");

			options = new .();
			window = new .();

			resources = new .();
			Gfxa.Init();

			textures = new .();

			camera = new .();
			tickCounter = new .(20, 0);

			camera.pos.y = 160;
			camera.yaw = 45;

			I18N.Load();
			Blocks.Register();
			BlockModelLoader.LoadModels();
			Biomes.Register();
			Biome.LoadColormaps();
			EntityTypes.Register();
			Buffers.CreateGlobalIndices();
			SkyRenderer.Init();
		}

		public ~this() {
			Gfx.Shutdown();
		}

		public void Join(StringView address, int32 port, int32 viewDistance) {
			connection = new .(address, port, viewDistance);
			window.MouseHidden = true;
		}

		private void Tick() {
			world.Tick();

			textures.Tick();
		}

		public void Render(bool mipmaps, bool sortChunks, bool chunkBoundaries, float delta) {
			if (world == null) return;

			camera.FlightMovement(delta);
			camera.Update();

			int tickCount = tickCounter.BeginRenderTick();
			for (int i < Math.Min(10, tickCount)) Tick();

			world.Render(camera, tickCounter.tickDelta, mipmaps, sortChunks);
			if (chunkBoundaries) world.RenderChunkBoundaries(camera);
		}
	}
}