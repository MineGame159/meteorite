using System;

using ImGui;

namespace Cacti;

static class ImGuiCacti {
	private static bool initialized;
	private static bool firstFrame = true;
	private static bool newFrameCalled;

	public static void Init(Window window) {
		ImGui.CHECKVERSION();
		ImGui.CreateContext();
		ImGui.StyleColorsDark();
		ImGui.GetStyle().Alpha = 0.9f;

		ImGuiImplGlfw.InitForOther(window.[Friend]handle, true);
		ImGuiImplCacti.Init();

		initialized = true;
	}

	public static void Destroy() {
		if (!initialized) return;

		ImGuiImplCacti.Shutdown();
		ImGuiImplGlfw.Shutdown();
		ImGui.DestroyContext();
	}

	public static bool NewFrame() {
		if (!initialized) return false;

		if (firstFrame) {
			ImGuiImplCacti.CreateFontsTexture();
			return false;
		}

		ImGuiImplCacti.NewFrame();
		ImGuiImplGlfw.NewFrame();
		ImGui.NewFrame();

		newFrameCalled = true;
		return true;
	}

	public static CommandBuffer Render(GpuImage image) {
		if (!initialized) return null;

		if (firstFrame) {
			firstFrame = false;
			return null;
		}

		if (!newFrameCalled) return null;
		newFrameCalled = false;

		ImGui.Render();
		return ImGuiImplCacti.Render(image, ImGui.GetDrawData());
	}
}