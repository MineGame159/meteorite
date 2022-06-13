using System;
using System.IO;
using System.Collections;

namespace Meteorite {
	class Meteorite {
		public static Meteorite INSTANCE;

		public Options options ~ delete _;
		public Window window ~ delete _;
		public ResourceLoader resources ~ delete _;
		public TextureManager textures ~ delete _;

		public Camera camera ~ delete _;
		public RenderTickCounter tickCounter ~ delete _;

		public BufferBumpAllocator frameBuffers;
		public GameRenderer gameRenderer;
		public WorldRenderer worldRenderer;
		public BlockEntityRenderDispatcher blockEntityRenderDispatcher;
		public TextRenderer textRenderer;
		public HudRenderer hud;

		public ClientConnection connection;
		public World world;
		public ClientPlayerEntity player;

		private List<delegate void()> tasks = new .() ~ DeleteContainerAndItems!(_);

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

			frameBuffers = new .();
			gameRenderer = new .();
			blockEntityRenderDispatcher = new .();
			textRenderer = new .();
			hud = new .();

			camera.pos.y = 160;
			camera.yaw = 45;

			I18N.Load();
			VoxelShapes.Init();
			Blocks.Register();
			BlockModelLoader.LoadModels();
			Biomes.Register();
			Biome.LoadColormaps();
			EntityTypes.Register();
			Buffers.CreateGlobalIndices();
			SkyRenderer.Init();
			BlockColors.Init();
			Screenshots.Init();
		}

		public ~this() {
			// Rendering needs to be deleted before Gfx is shut down
			delete hud;
			delete textRenderer;
			delete blockEntityRenderDispatcher;
			delete worldRenderer;
			delete gameRenderer;
			delete frameBuffers;

			// Connection needs to be deleted before world
			delete connection;
			delete world;

			Gfx.Shutdown();
		}

		public void Join(StringView address, int32 port, int32 viewDistance) {
			connection = new .(address, port, viewDistance);
			window.MouseHidden = true;
		}

		public void Disconnect(Text reason) {
			if (connection == null) return;

			DeleteAndNullify!(worldRenderer);
			DeleteAndNullify!(world);
			player = null;
			DeleteAndNullify!(connection);

			window.MouseHidden = false;

			Log.Info("Disconnected: {}", reason);
		}

		public void Execute(delegate void() task) {
			tasks.Add(task);
		}

		private void Tick(float tickDelta) {
			if (connection != null && connection.closed) {
				DeleteAndNullify!(connection);
				window.MouseHidden = false;
			}

			for (let task in tasks) {
				task();
				delete task;
			}
			tasks.Clear();

			if (world == null) return;

			world.Tick();

			textures.Tick();

			if (!window.minimized) gameRenderer.Tick();
		}

		public void Render(float delta) {
			int tickCount = tickCounter.BeginRenderTick();
			for (int i < Math.Min(10, tickCount)) Tick(tickCounter.tickDelta);
			
			if (!window.minimized) gameRenderer.Render(delta);

			frameBuffers.Reset();
		}
	}
}