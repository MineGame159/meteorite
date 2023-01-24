using System;

using GLFW;

namespace Cacti {
	class Window {
		private GlfwWindow* handle;
		private String title = new .() ~ delete _;

		public Vec2i size;
		public bool minimized;

		private bool mouseHidden;
		private bool firstCursorPos = true;

		public this(StringView title) {
			size = .(1280, 720);
			Title = title;

			if (Glfw.Init()) Log.Info("Initialized GLFW");
			else Log.ErrorResult("Failed to initialize GLFW");

			Glfw.WindowHint(.Visible, false);
			Glfw.WindowHint(.ClientApi, Glfw.ClientApi.NoApi);
			handle = Glfw.CreateWindow(size.x, size.y, this.title, null, null);

			if (handle != null) Log.Info("Created window");
			else Log.ErrorResult("Failed to create window");

			Glfw.SetFramebufferSizeCallback(handle, new (window, width, height) => {
				if (width == 0 || height == 0) {
					minimized = true;
					return;
				}

				size = .(width, height);
				minimized = false;

				Gfx.Swapchain.Recreate(size);
			});

			Glfw.SetMouseButtonCallback(handle, new (window, button, action, mods) => {
				for (let callback in Input.buttonEvent) {
					callback(button, action);
				}
			});

			Glfw.SetCursorPosCallback(handle, new (window, x, y) => {
				Input.mouse = .((.) x, (.) (Height - y));

				if (firstCursorPos) {
					Input.mouseLast = Input.mouse;
					firstCursorPos = false;
				}

				for (let callback in Input.mousePosEvent) {
					callback();
				}
			});

			Glfw.SetKeyCallback(handle, new (window, key, scancode, action, mods) => {
				Input.[Friend]keys[(.) key] = action != .Release;

				for (let callback in Input.keyEvent) {
					if (callback(key, scancode, action)) break;
				}
			});

			Glfw.SetCharCallback(handle, new (window, char) => {
				for (let callback in Input.charEvent) {
					if (callback((.) char)) break;
				}
			});

			Glfw.SetScrollCallback(handle, new (window, x, y) => {
				for (let callback in Input.scrollEvent) {
					if (callback((.) y)) break;
				}
			});

			Gfx.Init(this);

			Glfw.ShowWindow(handle);
		}

		public int Width => size.x;
		public int Height => size.y;

		public StringView Title {
			get => title;
			set {
				title.Set(value);

#if DEBUG
				title.Append(" (DEBUG)");
#endif

				if (handle != null) Glfw.SetWindowTitle(handle, title);
			}
		}

		public bool MouseHidden {
			get => mouseHidden;
			set {
				if (mouseHidden != value) Glfw.SetInputMode(handle, .Cursor, value ? GlfwInput.CursorInputMode.Disabled : GlfwInput.CursorInputMode.Normal);
				mouseHidden = value;
			}
		}

		public bool Open => !Glfw.WindowShouldClose(handle);

		public void Close() => Glfw.SetWindowShouldClose(handle, true);

		public void PollEvents() {
			Input.[Friend]Update();
			Glfw.PollEvents();
		}
	}
}