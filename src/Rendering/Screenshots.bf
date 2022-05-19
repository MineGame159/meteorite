using System;
using System.IO;

using Wgpu;
using ImGui;

namespace Meteorite{
	static class Screenshots {
		public static bool rendering;
		public static int width, height;
		public static int originalWidth, originalHeight;
		public static Texture texture;

		private static WBuffer buffer;
		private static bool windowOpen, take, wasMouseHidden;

		private static char8*[?] resolutions = .("Current", "(720p) 1280x720", "(1080p) 1920x1080", "(2k) 2048x1080", "(1440p) 2560x1440", "(4k) 4096x2160", "(8k) 7680x4320");

		private static int32 resolution;
		private static float scale;
		public static bool includeGui;

		public static bool Update() {
			Window window = Meteorite.INSTANCE.window;

			if (take) {
				Take(window);
				take = false;

				return false;
			}

			if (windowOpen) {
				if (Input.IsKeyDown(.Escape)) {
					windowOpen = false;
					window.MouseHidden = wasMouseHidden;

					return true;
				}

				return false;
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

			return false;
		}

		private static void Take(Window window) {
			rendering = true;
			originalWidth = window.width;
			originalHeight = window.height;

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
				width = originalWidth;
				height = originalHeight;
			}

			width = (.) (width * scale);
			height = (.) (height * scale);

			texture = Gfx.CreateTexture(.RenderAttachment | .CopySrc, width, height, 1, null, .BGRA8Unorm);

			Gfx.[Friend]CreateDepthTexture(width, height);
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

		public static void AfterRender2() {
			buffer.[Friend]handle.MapAsync(.Read, 0, buffer.size, => AfterMap, null);
		}

		private static void AfterMap(Wgpu.BufferMapAsyncStatus status, void* userdata) {
			if (status == .Success) {
				uint8* data = (.) buffer.[Friend]handle.GetMappedRange(0, buffer.size);

				StreamWriter w = new .();
				w.Create("run/screenshot.ppm");

				w.WriteLine("P3");
				w.WriteLine("{} {}", width, height);
				w.WriteLine("255");

				for (int i < width * height) {
					uint8* pixel = &data[i * 4];

					uint8 b = *pixel;
					uint8 g = pixel[1];
					uint8 r = pixel[2];

					w.WriteLine("{} {} {}", r, g, b);
				}

				w.Flush();
				delete w;
				
				buffer.[Friend]handle.Unmap();
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