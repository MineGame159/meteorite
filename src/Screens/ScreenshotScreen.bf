using System;

using Cacti;
using Cacti.Graphics;
using ImGui;

namespace Meteorite;

class ScreenshotScreen : Screen {
	private ScreenshotOptions options = .();

	public this() : base("Screeshot") {}

	protected override void RenderImpl() {
		using (ImGuiOptions opts = .(200)) {
			opts.Combo("Resolution", ref options.resolution);
			opts.SliderFloat("Scale", ref options.scale, 0.75f, 2);
			opts.Checkbox("Include GUI", ref options.includeGui);
		}

		ImGuiCacti.Separator();
		
		if (ImGui.Button("Take", .NOneZero)) {
			Screenshots.Take(options);
			Meteorite.INSTANCE.Screen = null;
		}
	}
}