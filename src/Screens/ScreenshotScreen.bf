using System;

using Cacti;
using ImGui;

namespace Meteorite;

class ScreenshotScreen : Screen {
	private ScreenshotOptions options = .();

	public this() : base("Screeshot") {}

	protected override void RenderImpl() {
		ImGuiCacti.Combo("Resolution", ref options.resolution);
		ImGui.DragFloat("Scale", &options.scale, 0.1f, 1, 2);
		ImGui.Checkbox("Include GUI", &options.includeGui);
		
		if (ImGui.Button("Take", .NOneZero)) {
			Screenshots.Take(options);
			Meteorite.INSTANCE.Screen = null;
		}
	}
}