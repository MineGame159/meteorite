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

		ImGuiImplCacti.Init(window);

		initialized = true;
	}

	public static void Destroy() {
		if (!initialized) return;

		ImGuiImplCacti.Shutdown();
		ImGui.DestroyContext();
	}

	public static bool NewFrame() {
		if (!initialized) return false;

		if (firstFrame) {
			ImGuiImplCacti.CreateFontsTexture();
			return false;
		}

		ImGuiImplCacti.NewFrame();
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

	// Widgets

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

	public static void Separator() {
		float textHeight = ImGui.CalcTextSize(" ").y;

		ImGui.SetCursorPosY(ImGui.GetCursorPosY() + Math.Floor(textHeight / 2));
		ImGui.Separator();
		ImGui.SetCursorPosY(ImGui.GetCursorPosY() + Math.Ceiling(textHeight / 2));
	}

	public static void Separator(StringView text) {
		char8* textPtr = text.ToScopeCStr!();

		float windowWidth = ImGui.GetWindowSize().x;
		ImGui.Vec2 textSize = ImGui.CalcTextSize(textPtr);

		float textX = (windowWidth - textSize.x) * 0.5f;
		ImGui.SetCursorPosX(textX);

		ImGui.Vec4* textColor = ImGui.GetStyleColorVec4(.Separator);
		ImGui.TextColored(.(Math.Min(textColor.x + 25, 255), Math.Min(textColor.y + 25, 255), Math.Min(textColor.z + 25, 255), textColor.w), textPtr);

		ImGui.Vec2 windowPos = ImGui.GetWindowPos();
		ImGui.Vec2 spacing = ImGui.GetStyle().ItemSpacing;

		float y = windowPos.y + ImGui.GetCursorPosY() - textSize.y + spacing.y - 1;
		uint32 color = ImGui.GetColorU32(.Separator);

		ImGui.DrawList* drawList = ImGui.GetWindowDrawList();
		drawList.AddLine(.(windowPos.x + spacing.x, y), .(windowPos.x + textX - spacing.x, y), color);
		drawList.AddLine(.(windowPos.x + spacing.x + textX + textSize.x, y), .(windowPos.x + windowWidth - spacing.x, y), color);
	}
}