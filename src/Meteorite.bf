using System;
using System.IO;
using System.Collections;

using Cacti;
using Bulkan;

namespace Meteorite {
	class Meteorite : Application {
		public static Meteorite INSTANCE;

		public Options options ~ delete _;
		public ResourceLoader resources ~ delete _;
		public TextureManager textures ~ delete _;

		public Camera camera ~ delete _;
		public RenderTickCounter tickCounter ~ delete _;

		public GameRenderer gameRenderer;
		public LightmapManager lightmapManager;
		public WorldRenderer worldRenderer;
		public BlockEntityRenderDispatcher blockEntityRenderDispatcher;
		public EntityRenderDispatcher entityRenderDispatcher;
		public TextRenderer textRenderer;
		public HudRenderer hud;

		public ClientConnection connection;
		public World world;
		public ClientPlayerEntity player;

		private Screen screen;
		private List<delegate void()> tasks = new .() ~ DeleteContainerAndItems!(_);

		private GpuImage swapchainTarget;
		private bool afterScreenshot;

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
			lightmapManager = new .();
			blockEntityRenderDispatcher = new .();
			entityRenderDispatcher = new .();
			textRenderer = new .();
			hud = new .();

			camera.pos.y = 160;
			camera.yaw = 45;

			I18N.Load();
			VoxelShapes.Init();
			Blocks.Register();
			Items.Register();
			BlockModelLoader.LoadModels();
			Biomes.Register();
			ChatTypes.Register();
			Biome.LoadColormaps();
			Buffers.CreateGlobalIndices();
			SkyRenderer.Init();
			BlockColors.Init();
			FrameUniforms.Init();

			Input.keyEvent.Add(new (key, action) => {
				if (action == .Release && key == .O && !Input.capturingCharacters && world != null && player != null) {
					if (Screen is OptionsScreen) Screen = null;
					else Screen = new OptionsScreen();

					return true;
				}

				return false;
			});

			window.MouseHidden = true;
			Screen = new MainMenuScreen();
		}

		public ~this() {
			// Rendering needs to be deleted before Gfx is shut down
			delete screen;
			delete hud;
			delete textRenderer;
			delete entityRenderDispatcher;
			delete blockEntityRenderDispatcher;
			delete worldRenderer;
			delete lightmapManager;
			delete gameRenderer;

			FrameUniforms.Destroy();
			SkyRenderer.Destroy();
			Buffers.Destroy();
			Gfxa.Destroy();

			// Connection needs to be deleted before world
			delete connection;
			delete world;
		}

		public void Join(StringView address, int32 port, StringView username) {
			connection = new .(address, port, username);
			Screen = null;
		}

		public void Disconnect(Text reason) {
			if (connection == null) return;

			DeleteAndNullify!(worldRenderer);
			DeleteAndNullify!(world);
			player = null;
			DeleteAndNullify!(connection);

			Screen = new MainMenuScreen();

			Log.Info("Disconnected: {}", reason);
		}

		public Screen Screen {
			get => screen;
			set {
				screen?.Close();
				delete screen;

				screen = value;
				screen?.Open();
			}
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
			Screenshots.Update();

			if (player != null && window.MouseHidden) player.Turn(Input.mouseDelta);

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
		
		protected override CommandBuffer AfterRender(GpuImage target) {
			if (Screenshots.rendering) {
				CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();

				cmds.Begin();
				cmds.PushDebugGroup("Screenshot");

				cmds.CopyImageToBuffer(target, Screenshots.buffer);
				cmds.BlitImage(Screenshots.texture, swapchainTarget);

				cmds.PopDebugGroup();
				cmds.End();

				afterScreenshot = true;
				return cmds;
			}

			return null;
		}

		protected override GpuImage GetTargetImage(VkSemaphore imageAvailableSemaphore) {
			if (afterScreenshot) {
				Screenshots.Save();
				afterScreenshot = false;
			}
			
			swapchainTarget = Gfx.Swapchain.GetImage(imageAvailableSemaphore);
			return Screenshots.rendering ? Screenshots.texture : swapchainTarget;
		}
		
		protected override GpuImage GetPresentImage() => swapchainTarget;
	}
}