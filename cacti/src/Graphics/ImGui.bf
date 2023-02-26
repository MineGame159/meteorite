using System;
using System.Collections;

using ImGui;

namespace Cacti.Graphics;

static class ImGuiCacti {
	private static bool initialized;
	private static bool firstFrame = true;
	private static bool newFrameCalled;

	private static SimpleBumpAllocator frameAlloc = new .() ~ delete _;
	private static int id;

	public static bool customSize = false;
	public static Vec2i size;

	[Tracy.Profile]
	public static void Init(Window window) {
		// TODO: For some reason when the application is built on a GitHub action runner the size of ImGui.IO struct is smaller than what it should be
		//       But it looks like it doesn't break anything surprisingly
		//ImGui.CHECKVERSION();

		ImGui.CreateContext();
		ImGui.StyleColorsDark();
		ImGui.GetStyle().Alpha = 0.9f;

		ImGui.IO* io = ImGui.GetIO();
		io.Fonts.AddFontFromFileTTF("assets/meteorite/FiraCode-Regular.ttf", 16);

		ImGuiImplCacti.Init(window);

		initialized = true;
	}

	public static void Destroy() {
		if (!initialized) return;

		ImGuiImplCacti.Shutdown();
		ImGui.DestroyContext();
	}
	
	[Tracy.Profile]
	public static bool NewFrame() {
		if (!initialized) return false;

		frameAlloc.FreeAll();

		if (firstFrame) {
			ImGuiImplCacti.CreateFontsTexture();
			return false;
		}

		ImGuiImplCacti.NewFrame();
		ImGui.NewFrame();

		id = 0;

		newFrameCalled = true;
		return true;
	}
	
	[Tracy.Profile]
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

	public static int GetId() => id++;

	public static mixin GetStringId() {
		scope:mixin $"##{GetId()}"
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

		float y = windowPos.y + ImGui.GetCursorPosY() - textSize.y + spacing.y;
		uint32 color = ImGui.GetColorU32(.Separator);

		ImGui.DrawList* drawList = ImGui.GetWindowDrawList();
		drawList.AddLine(.(windowPos.x + spacing.x, y), .(windowPos.x + textX - spacing.x, y), color);
		drawList.AddLine(.(windowPos.x + spacing.x + textX + textSize.x, y), .(windowPos.x + windowWidth - spacing.x, y), color);
	}
}

struct ImGuiOptions : IDisposable {
	private bool ok;
	private int width;

	public this(int width) {
		this.ok = !ImGui.IsWindowCollapsed();
		this.width = width;
		
		if (ok) {
			ImGui.BeginTable(ImGuiCacti.GetStringId!(), 2);
		}
	}

	public void Dispose() {
		if (ok) {
			ImGui.EndTable();
		}
	}

	public bool Checkbox(StringView label, ref bool value) {
		if (!ok) return false;

		ImGui.TableNextRow();
		ImGui.TableNextColumn();

		ImGui.AlignTextToFramePadding();
		ImGui.Text(label.ToScopeCStr!());

		ImGui.TableNextColumn();
		PushItemWidth();
		return ImGui.Checkbox(scope $"##{label}", &value);
	}

	public bool SliderInt(StringView label, ref int value, int min, int max, ImGui.SliderFlags flags = .None) {
		if (!ok) return false;

		int32 _value = (.) value;

		ImGui.TableNextRow();
		ImGui.TableNextColumn();

		ImGui.AlignTextToFramePadding();
		ImGui.Text(label.ToScopeCStr!());

		ImGui.TableNextColumn();
		PushItemWidth();
		bool changed = ImGui.SliderInt(scope $"##{label}", &_value, (.) min, (.) max, flags: flags);

		value = _value;
		return changed;
	}

	public bool SliderFloat(StringView label, ref float value, float min, float max, StringView format = "%.3f", ImGui.SliderFlags flags = .None) {
		if (!ok) return false;

		ImGui.TableNextRow();
		ImGui.TableNextColumn();

		ImGui.AlignTextToFramePadding();
		ImGui.Text(label.ToScopeCStr!());

		ImGui.TableNextColumn();
		PushItemWidth();
		return ImGui.SliderFloat(scope $"##{label}", &value, min, max, format.ToScopeCStr!(), flags);
	}

	public bool InputText(StringView label, String str, int maxLength, ImGui.InputTextFlags flags = .None) {
		if (!ok) return false;

		str.[Friend]CalculatedReserve(maxLength);
		char8[] buffer = new:ScopedAlloc! .[maxLength];

		if (str.Length > 0) {
			Internal.MemCpy(buffer.Ptr, str.Ptr, Math.Min(str.Length, maxLength));
		}

		ImGui.TableNextRow();
		ImGui.TableNextColumn();

		ImGui.AlignTextToFramePadding();
		ImGui.Text(label.ToScopeCStr!());

		ImGui.TableNextColumn();
		PushItemWidth();
		bool changed = ImGui.InputText(scope $"##{label}", buffer.Ptr, (.) buffer.Count, flags);

		str.Set(StringView(buffer.Ptr));
		return changed;
	}

	public bool Combo<T>(StringView label, ref T value) where T : enum {
		if (!ok) return false;

		ImGui.TableNextRow();
		ImGui.TableNextColumn();

		ImGui.AlignTextToFramePadding();
		ImGui.Text(label.ToScopeCStr!());

		ImGui.TableNextColumn();
		PushItemWidth();

		String str = scope .();
		value.ToString(str);

		if (!ImGui.BeginCombo(scope $"##{label}", str)) {
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

	private void PushItemWidth() {
		float availableWidth = ImGui.GetWindowContentRegionMax().x - ImGui.GetCursorPosX();
		ImGui.PushItemWidth(Math.Max(width, availableWidth));
	}
}

struct ImGuiButtons : IDisposable {
	private float width;
	private int i = 0;

	public this(int count) {
		float spacing = ImGui.GetStyle().ItemSpacing.x;
		this.width = ImGui.GetWindowContentRegionMax().x / count - spacing;
	}

	public void Dispose() {}

	public bool Button(StringView label, ImGui.ButtonFlags flags = .None) mut {
		if (i++ > 0) {
			ImGui.SameLine();
		}

		return ImGui.Button(label.ToScopeCStr!(), .(width, 0));
	}
}

struct ImGuiTextList : IDisposable {
	public const int MAX_COUNT = 32;

	private float spaceWidth;

	private Entry[MAX_COUNT] entries;
	private int entryCount;

	public this() {
		this.spaceWidth = ImGui.CalcTextSize(" ").x;

		this.entries = ?;
		this.entryCount = 0;
	}

	public void Dispose() {
		// Calculate max left width
		float leftWidth = 0;

		for (int i < entryCount) {
			let entry = entries[i];

			if (!entry.separator) {
				leftWidth = Math.Max(leftWidth, ImGui.CalcTextSize(entry.left.Ptr).x);
			}
		}

		// Calculate max right width
		float rightWidth = 0;

		for (int i < entryCount) {
			let entry = entries[i];

			if (!entry.separator) {
				rightWidth = Math.Max(rightWidth, ImGui.CalcTextSize(entry.right.Ptr).x);
			}
		}

		// Calculate width
		float width = Math.Max(leftWidth + spaceWidth * 2 + rightWidth, ImGui.GetContentRegionMax().x);

		// Display
		ImGui.PushItemWidth(width);

		for (int i < entryCount) {
			let entry = entries[i];

			if (entry.separator) {
				ImGui.Separator();
			}
			else {
				ImGui.[Friend]TextImpl(entry.left.Ptr);

				ImGui.SameLine(width - ImGui.CalcTextSize(entry.right.Ptr).x);
				ImGui.[Friend]TextImpl(entry.right.Ptr);
			}

			entry.Delete(ImGuiCacti.[Friend]frameAlloc);
		}

		ImGui.PopItemWidth();
	}

	public void Text(StringView left, StringView right) mut {
		if (entryCount >= MAX_COUNT) Internal.FatalError("Exceeded maximum entry count");

		mixin Alloc(StringView str) {
			let alloc = ImGuiCacti.[Friend]frameAlloc;
			String copy = new:alloc .(str.Length + 1);

			copy.Append(str);
			copy.Append('\0');

			copy
		}

		entries[entryCount++] = .(Alloc!(left), Alloc!(right), false);
	}

	public void Text(StringView left, String right) mut {
		Text(left, (StringView) right);
	}

	public void Text<T>(StringView left, T right) mut {
		Text(left, (StringView) right.ToString(.. scope .()));
	}

	public void Separator() mut {
		if (entryCount >= MAX_COUNT) Internal.FatalError("Exceeded maximum entry count");

		entries[entryCount++] = .(null, null, true);
	}

	struct Entry : this(String left, String right, bool separator) {
		public void Delete(IRawAllocator alloc) {
			if (!separator) {
				delete:alloc left;
				delete:alloc right;
			}
		}
	}
}