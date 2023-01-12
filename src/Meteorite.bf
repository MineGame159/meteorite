using System;
using System.IO;
using System.Collections;

using Cacti;

namespace Meteorite {
	class Meteorite : Application {
		public static Meteorite INSTANCE;

		public Options options ~ delete _;
		public ResourceLoader resources ~ delete _;
		public TextureManager textures ~ delete _;

		public Camera camera ~ delete _;
		public RenderTickCounter tickCounter ~ delete _;

		public GameRenderer gameRenderer;
		public WorldRenderer worldRenderer;
		public BlockEntityRenderDispatcher blockEntityRenderDispatcher;
		public EntityRenderDispatcher entityRenderDispatcher;
		public TextRenderer textRenderer;
		public HudRenderer hud;

		public ClientConnection connection;
		public World world;
		public ClientPlayerEntity player;

		private List<delegate void()> tasks = new .() ~ DeleteContainerAndItems!(_);

		public this() : base("Meteorite") {
			INSTANCE = this;
			Directory.CreateDirectory("run");

			options = new .();

			resources = new .();
			Gfxa.Init();

			textures = new .();

			camera = new .(window);
			tickCounter = new .(20, 0);

			EntityTypes.Register();

			gameRenderer = new .();
			blockEntityRenderDispatcher = new .();
			entityRenderDispatcher = new .();
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
			Buffers.CreateGlobalIndices();
			SkyRenderer.Init();
			BlockColors.Init();
			// TODO: Screenshots
			//Screenshots.Init();
			FrameUniforms.Init();

			Input.mousePosEvent.Add(new () => {
				ClientPlayerEntity player = Meteorite.INSTANCE.player;
				if (player != null && window.MouseHidden) player.Turn(Input.mouseDelta);
			});
		}

		public ~this() {
			// Rendering needs to be deleted before Gfx is shut down
			delete hud;
			delete textRenderer;
			delete entityRenderDispatcher;
			delete blockEntityRenderDispatcher;
			delete worldRenderer;
			delete gameRenderer;

			FrameUniforms.Destroy();
			SkyRenderer.Destroy();
			Buffers.Destroy();
			Gfxa.Destroy();

			// Connection needs to be deleted before world
			delete connection;
			delete world;
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

		protected override void Update(double delta) {
			int tickCount = tickCounter.BeginRenderTick();
			for (int i < Math.Min(10, tickCount)) Tick(tickCounter.tickDelta);
		}

		protected override void Render(List<CommandBuffer> commandBuffers, GpuImage target, double delta) {
			if (!window.minimized) {
				CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
				commandBuffers.Add(cmds);

				gameRenderer.Render(cmds, target, (.) delta);
			}
		}
	}
}