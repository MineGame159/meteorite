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

		public ClientConnection connection;
		public World world;
		public ClientPlayerEntity player;

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
			BlockColors.Init();
		}

		public ~this() {
			// Connection needs to be deleted before world
			delete connection;
			delete world;

			Gfx.Shutdown();
		}

		public void Join(StringView address, int32 port, int32 viewDistance) {
			connection = new .(address, port, viewDistance);
			window.MouseHidden = true;
		}

		private void Tick(float tickDelta) {
			world.Tick();

			textures.Tick();
		}

		public void Render(bool mipmaps, bool sortChunks, bool chunkBoundaries, float delta) {
			if (world == null) return;

			int tickCount = tickCounter.BeginRenderTick();
			for (int i < Math.Min(10, tickCount)) Tick(tickCounter.tickDelta);

			if (!window.minimized) {
				if (player != null && player.gamemode == .Spectator) {
					Vec3d pos = player.pos.Lerp(tickCounter.tickDelta, player.lastPos);
					camera.pos = .((.) (pos.x + player.type.width / 2), (.) pos.y + 1.62f, (.) (pos.z + player.type.width / 2));
					camera.yaw = player.yaw;
					camera.pitch = player.pitch;
				}
				else camera.FlightMovement(delta);
				camera.Update();

				world.Render(camera, delta, tickCounter.tickDelta, mipmaps, sortChunks);
				if (chunkBoundaries) world.RenderChunkBoundaries(camera);
			}
		}
	}
}