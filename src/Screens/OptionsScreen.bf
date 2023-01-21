using System;

using Cacti;
using ImGui;

namespace Meteorite;

class OptionsScreen : Screen {
	public this() : base("Options") {}

	protected override void RenderImpl() {
		Meteorite me = Meteorite.INSTANCE;

		ImGui.Checkbox("Chunk Boundaries", &me.options.chunkBoundaries);
		ImGui.SliderFloat("FOV", &me.options.fov, 10, 170, "%.0f");

		AO prevAo = me.options.ao;
		if (ImGuiCacti.Combo("SSAO", ref me.options.ao)) {
			bool prevVanilla = prevAo.HasVanilla;
			bool prevSsao = prevAo.HasSSAO;

			if (prevVanilla != me.options.ao.HasVanilla) {
				me.world.ReloadChunks();
			}
			
			if (prevSsao != me.options.ao.HasSSAO) {
				Gfxa.POST_PIPELINE.Reload();
				me.gameRenderer.[Friend]ssao?.pipeline.Reload();
			}
		}
		if (ImGui.Checkbox("FXAA", &me.options.fxaa)) Gfxa.POST_PIPELINE.Reload();

		ImGui.Separator();
		if (ImGui.Button("Disconnect", .NOneZero)) {
			Gfx.RunOnNewFrame(new () => {
				Text text = .Of("Disconnected");
				me.Disconnect(text);

				delete text;
			});
		}
	}
}