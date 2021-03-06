using System;

using Wgpu;
using ImGui;

namespace Meteorite{
	static class Screenshots {
		public static bool rendering;
		public static int width, height;
		public static Texture texture;

		private static WBuffer buffer;
		private static bool windowOpen, take, wasMouseHidden;

		private static char8*[?] resolutions = .("Current", "(720p) 1280x720", "(1080p) 1920x1080", "(2k) 2048x1080", "(1440p) 2560x1440", "(4k) 4096x2160", "(8k) 7680x4320");

		private static int32 resolution;
		private static float scale;
		public static bool includeGui;

		public static void Init() {
			Input.keyEvent.Add(new => OnKey);
		}

		private static bool OnKey(Key key, InputAction action) {
			if (action != .Press) return false;

			if (windowOpen && key == .Escape) {
				windowOpen = false;
				Meteorite.INSTANCE.window.MouseHidden = wasMouseHidden;
				return true;
			}

			return false;
		}

		public static void Update() {
			Window window = Meteorite.INSTANCE.window;

			if (take) {
				Take(window);
				take = false;

				return;
			}

			if (Input.IsKeyPressed(.F2)) {
				resolution = 0;
				scale = 1;
				includeGui = false;

				if (Input.IsKeyDown(.LeftControl) || Input.IsKeyDown(.RightControl)) {
					windowOpen = true;
					wasMouseHidden = window.MouseHidden;
				}
				else Take(window);
			}
		}

		private static void Take(Window window) {
			rendering = true;

			switch (resolution) {
			case 1:
				width = 1280;
				height = 720;
			case 2:
				width = 1920;
				height = 1080;
			case 3:
				width = 2048;
				height = 1080;
			case 4:
				width = 2560;
				height = 1440;
			case 5:
				width = 4096;
				height = 2160;
			case 6:
				width = 7680;
				height = 4320;
			default:
				width = window.width;
				height = window.height;
			}

			width = (.) (width * scale);
			height = (.) (height * scale);

			texture = Gfx.CreateTexture(.RenderAttachment | .CopySrc, width, height, 1, null, .BGRA8Unorm);
		}

		public static void AfterRender(Wgpu.CommandEncoder encoder) {
			buffer = Gfx.CreateBuffer(.CopyDst | .MapRead, width * height * 4);

			Wgpu.ImageCopyTexture src = .() {
				texture = texture.[Friend]handle,
				mipLevel = 0,
				origin = .(),
				aspect = .All
			};
			Wgpu.ImageCopyBuffer dst = .() {
				layout = .() {
					offset = 0,
					bytesPerRow = (.) width * 4,
					rowsPerImage = (.) height
				}
				buffer = buffer.[Friend]handle,
			};
			Wgpu.Extent3D size = .((.) width, (.) height, 1);
			encoder.CopyTextureToBuffer(&src, &dst, &size);
		}

		public static void Save() {
			buffer.[Friend]handle.MapAsync(.Read, 0, buffer.size, => AfterMap, null);
		}

		private static void AfterMap(Wgpu.BufferMapAsyncStatus status, void* userdata) {
			if (status == .Success) {
				uint8* data = (.) buffer.[Friend]handle.GetMappedRange(0, buffer.size);

				Image image = scope .(width, height, 4, data, false);
				image.Write("run/screenshot.png", true);

				Log.Info("Saved screenshot to run/screenshot.png");
			}
			else Log.Error("Failed to map screenshot buffer: {}", status);

			delete buffer;
			delete texture;
		}

		public static void Render() {
			Window window = Meteorite.INSTANCE.window;

			if (!windowOpen) return;
			if (window.MouseHidden) window.MouseHidden = false;

			ImGui.IO* io = ImGui.GetIO();
			ImGui.SetNextWindowPos(.(io.DisplaySize.x / 2, io.DisplaySize.y / 2), .Appearing, .(0.5f, 0.5f));
			ImGui.Begin("Screenshot", null, .AlwaysAutoResize);

			ImGui.Combo("Resolution", &resolution, &resolutions, resolutions.Count);
			ImGui.DragFloat("Scale", &scale, 0.1f, 1, 2);
			ImGui.Checkbox("Include GUI", &includeGui);

			if (ImGui.Button("Take", .NOneZero)) {
				take = true;
				windowOpen = false;
				window.MouseHidden = wasMouseHidden;
			}

			ImGui.End();
		}
	}
}