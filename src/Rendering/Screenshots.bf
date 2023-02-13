using System;

using Cacti;
using Cacti.Graphics;
using ImGui;

namespace Meteorite;

enum ScreenshotResolution {
	case Current,
		 _720,
		_1080,
		_2k,
		 _1440,
		_4k,
		_8k;

	public override void ToString(String str) {
		switch (this) {
		case .Current:	str.Append("Current");
		case ._720:		str.Append("(720p) 1280x720");
		case ._1080:	str.Append("(1080p) 1920x1080");
		case ._2k:		str.Append("(2k) 2048x1080");
		case ._1440:	str.Append("(1440p) 2560x1440");
		case ._4k:		str.Append("(4k) 4096x2160");
		case ._8k:		str.Append("(8k) 7680x4320");
		}
	}
}

struct ScreenshotOptions {
	public ScreenshotResolution resolution = .Current;
	public float scale = 1;
	public bool includeGui = false;
}

static class Screenshots {
	public static bool rendering;
	public static int width, height;
	public static GpuImage texture;

	public static ScreenshotOptions options;

	public static GpuBuffer buffer;
	private static bool take, wasMouseHidden;

	private static Vec2i prevSize;

	public static void Update() {
		if (take) {
			TakeActually();
			take = false;

			return;
		}

		if (Input.IsKeyPressed(.F2)) {
			if (Input.IsKeyDown(.LeftControl) || Input.IsKeyDown(.RightControl)) {
				if (Meteorite.INSTANCE.Screen is ScreenshotScreen) Meteorite.INSTANCE.Screen = null;
				else Meteorite.INSTANCE.Screen = new ScreenshotScreen();
			}
			else Take();
		}
	}

	public static void Take(ScreenshotOptions options = .()) {
		Screenshots.options = options;
		take = true;
	}

	private static void TakeActually() {
		Window window = Meteorite.INSTANCE.window;
		rendering = true;

		switch (options.resolution) {
		case ._720:
			width = 1280;
			height = 720;
		case ._1080:
			width = 1920;
			height = 1080;
		case ._2k:
			width = 2048;
			height = 1080;
		case ._1440:
			width = 2560;
			height = 1440;
		case ._4k:
			width = 4096;
			height = 2160;
		case ._8k:
			width = 7680;
			height = 4320;
		default:
			width = window.Width;
			height = window.Height;
		}

		prevSize = window.size;

		width = (.) (width * options.scale);
		height = (.) (height * options.scale);

		texture = Gfx.Images.Create("Screenshot", .BGRA, .ColorAttachment, .(width, height));
		buffer = Gfx.Buffers.Create("Screenshot", .None, .TransferDst | .Mappable, texture.GetByteSize());

		ImGuiCacti.customSize = true;
		ImGuiCacti.size = .(width, height);
	}

	public static void Save() {
		rendering = false;

		Meteorite.INSTANCE.window.size = prevSize;
		ImGuiCacti.customSize = false;

		if (buffer.Map() case .Ok(let data)) {
			Image image = scope .(texture.Size, 4, (.) data, false);
			image.Write("run/screenshot.png", true);

			Log.Info("Saved screenshot to run/screenshot.png");
		}
		else {
			Log.Error("Failed to map screenshot buffer");
		}

		ReleaseAndNullify!(buffer);
		ReleaseAndNullify!(texture);
	}
}