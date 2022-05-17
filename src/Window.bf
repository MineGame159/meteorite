using System;
using GLFW;
using Wgpu;

namespace Meteorite {
	class Window {
		public GlfwWindow* handle;

		public int width, height;

		private bool firstCursorPos = true;

		public this() {
			if (Glfw.Init()) Log.Info("Initialized GLFW");
			else Log.Error("Failed to initialize GLFW");

			width = 1280;
			height = 720;

			Glfw.WindowHint(.ClientApi, Glfw.ClientApi.NoApi);
			Glfw.WindowHint(.Visible, false);
			handle = Glfw.CreateWindow(width, height, "Meteorite", null, null);
			Log.Info("Created window");

			Wgpu.SetLogLevel(.Warn);
			Wgpu.SetLogCallback(=> WgpuLogCallback);

			Wgpu.InstanceDescriptor instanceDesc = .() {};
			Wgpu.Instance instance = Wgpu.CreateInstance(&instanceDesc);

			Wgpu.Surface surface = Wgpu.CreateSurfaceFromGlfw(instance, handle);

			Wgpu.RequestAdapterOptions options = .() {
				compatibleSurface = surface,
				powerPreference = .HighPerformance,
				forceFallbackAdapter = false
			};
			Wgpu.Adapter adapter = .Null;
			instance.RequestAdapter(&options, (status, adapter, message, userdata) => *(Wgpu.Adapter*) userdata = adapter, &adapter);

			Wgpu.RequiredLimitsExtras limitsExtras = .() {
				chain = .() {
					sType = (.) Wgpu.NativeSType.RequiredLimitsExtras
				},
				maxPushConstantSize = 128
			};
			Wgpu.RequiredLimits limits = .() {
				nextInChain = (.) &limitsExtras,
				limits = .Default()
			};
			limits.limits.maxTextureDimension2D *= 2;
			Wgpu.DeviceExtras deviceExtras = .() {
				chain = .() {
					sType = (.) Wgpu.NativeSType.Extras
				},
				nativeFeatures = .PUSH_CONSTANTS
			};
			Wgpu.DeviceDescriptor deviceDesc = .() {
				nextInChain = (.) &deviceExtras,
				requiredLimits = &limits,
				defaultQueue = .() {}
			};
			Wgpu.Device device = .Null;
			adapter.RequestDevice(&deviceDesc, (status, device, message, userdata) => *(Wgpu.Device*) userdata = device, &device);

			device.SetUncapturedErrorCallback((type, message, userdata) => Console.WriteLine("{}: {}", type, StringView(message)), null);

			Glfw.SetFramebufferSizeCallback(handle, new (window, width, height) => {
				this.width = width;
				this.height = height;
				
				Gfx.[Friend]CreateSwapChain(width, height);
				Gfx.[Friend]CreateDepthTexture(width, height);
			});

			Glfw.SetCursorPosCallback(handle, new (window, x, y) => {
				Input.mouse = .((.) x, (.) (height - y));

				if (firstCursorPos) {
					Input.mouseLast = Input.mouse;
					firstCursorPos = false;
				}
			});

			Glfw.SetKeyCallback(handle, new (window, key, scancode, action, mods) => {
				Input.[Friend]keys[(.) key] = action != .Release;
			});

			Gfx.Init(this, surface, device, width, height);
			Glfw.ShowWindow(handle);
		}

		public ~this() {
			Glfw.DestroyWindow(handle);
			Glfw.Terminate();

			Log.Info("Terminated GLFW");
		}

		private bool mouseHidden;
		public bool MouseHidden {
			get => mouseHidden;
			set {
				if (mouseHidden != value) Glfw.SetInputMode(handle, .Cursor, value ? GlfwInput.CursorInputMode.Disabled : GlfwInput.CursorInputMode.Normal);
				mouseHidden = value;
			}
		}

		public bool ShouldClose {
			get => Glfw.WindowShouldClose(handle);
			set => Glfw.SetWindowShouldClose(handle, value);
		}

		public void PollEvents() => Glfw.PollEvents();
		public void SwapBuffers() => Glfw.SwapBuffers(handle);

		private static void WgpuLogCallback(Wgpu.LogLevel level, char8* msg) {
			switch (level) {
			case .Error: Log.Error("{}", StringView(msg));
			case .Warn:  Log.Warning("{}", StringView(msg));
			case .Info:  Log.Info("{}", StringView(msg));
			case .Debug: Log.Debug("{}", StringView(msg));
			case .Trace: Log.Trace("{}", StringView(msg));
			default:
			}
		}
	}
}