using System;

using ImGui;

namespace Cacti;

static class ImGuiCacti {
	private static bool initialized;
	private static bool firstFrame = true;
	private static bool newFrameCalled;

	public static bool customSize = false;
	public static Vec2i size;

	public static void Init(Window window) {
		// TODO: For some reason when the application is built on a GitHub action runner the size of ImGui.IO struct is smaller than what it should be
		//       But it looks like it doesn't break anything surprisingly
		//ImGui.CHECKVERSION();

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

	public static CommandBuffer Render(GpuImage target) {
		if (!initialized) return null;

		if (firstFrame) {
			firstFrame = false;
			return null;
		}

		if (!newFrameCalled) return null;
		newFrameCalled = false;

		ImGui.Render();
		return ImGuiImplCacti.Render(target, ImGui.GetDrawData());
	}

	public static bool Combo<T>(StringView label, ref T value) where T : enum {
		String str = scope .();
		value.ToString(str);

		if (!ImGui.BeginCombo(label.ToScopeCStr!(), str)) {
			return false;
		}

		bool valueChanged = false;

		for (T item in Enum.GetValues<T>()) {
			bool selected = item == value;

			str.Clear();
			item.ToString(str);

			if (ImGui.Selectable(str, selected)) {
				value = item;
				valueChanged = true;
			}

			if (selected) {
				ImGui.SetItemDefaultFocus();
			}
		}

		ImGui.EndCombo();

		if (valueChanged) {
			ImGui.MarkItemEdited(ImGui.GetCurrentContext().LastItemData.ID);
		}

		return valueChanged;
	}
}