using System;

using ImGui;

namespace Meteorite;

abstract class Screen {
	private String title ~ delete _;
	private bool wasMouseHidden;

	public this(StringView title) {
		this.title = new .(title);
	}

	public void Open() {
		wasMouseHidden = Meteorite.INSTANCE.window.MouseHidden;
		Meteorite.INSTANCE.window.MouseHidden = false;
	}

	public void Close() {
		Meteorite.INSTANCE.window.MouseHidden = wasMouseHidden;
	}

	public void Render() {
		Meteorite.INSTANCE.window.MouseHidden = false;

		ImGui.IO* io = ImGui.GetIO();
		ImGui.SetNextWindowPos(.(io.DisplaySize.x / 2, io.DisplaySize.y / 2), .Once, .(0.5f, 0.5f));
		ImGui.Begin(title, null, .AlwaysAutoResize);
		
		RenderImpl();

		ImGui.End();
	}

	protected abstract void RenderImpl();
}