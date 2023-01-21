using System;

using Cacti;
using ImGui;

namespace Meteorite;

class OptionsScreen : Screen {
	private bool vsync;
	private int32 renderDistance;

	public this() : base("Options") {
		vsync = Meteorite.INSTANCE.options.vsync;
		renderDistance = Meteorite.INSTANCE.options.renderDistance;
	}

	public ~this() {
		Options options = Meteorite.INSTANCE.options;

		options.vsync = vsync;
		options.renderDistance = renderDistance;
		options.Write();
		
		Meteorite.INSTANCE.connection?.Send(scope ClientSettingsC2SPacket());
	}

	protected override void RenderImpl() {
		Meteorite me = Meteorite.INSTANCE;

		ImGui.Checkbox("VSync", &vsync);

		ImGui.Separator();

		ImGui.SliderInt("Render Distance", &renderDistance, 2, 32);
		ImGui.SliderFloat("FOV", &me.options.fov, 10, 170, "%.0f");
		ImGui.SliderFloat("Mouse Sensitivity", &me.options.mouseSensitivity, 0.1f, 2);
		
		ImGui.Separator();

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

		ImGui.Checkbox("Chunk Boundaries", &me.options.chunkBoundaries);

		ImGui.Separator();

		float spacing = ImGui.GetStyle().ItemSpacing.x;
		float width = ImGui.GetWindowContentRegionMax().x / 2 - spacing;

		if (ImGui.Button("Disconnect", .(width, 0))) {
			Gfx.RunOnNewFrame(new () => {
				Text text = .Of("Disconnected");
				me.Disconnect(text);

				delete text;
			});
		}

		ImGui.SameLine();
		if (ImGui.Button("Close", .(width, 0))) {
			Meteorite.INSTANCE.Screen = null;
		}
	}
}