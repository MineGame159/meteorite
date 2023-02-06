using System;

using Cacti;
using ImGui;

namespace Meteorite;

class OptionsScreen : Screen {
	private Options options = Meteorite.INSTANCE.options;

	private bool vsync;
	private int32 renderDistance;
	private AAOptions aaOptions;

	public this() : base("Options") {
		Load();
	}

	public ~this() {
		Apply();
	}

	private void Load() {
		vsync = options.vsync;
		renderDistance = options.renderDistance;
		aaOptions = options.aa;
	}

	private void Apply() {
		options.vsync = vsync;
		options.renderDistance = renderDistance;

		// Anti Aliasing
		bool reloadPost = false;
		bool reloadSmaa = false;

		if (options.aa.enabled != aaOptions.enabled) reloadPost = true;
		if (options.aa.edgeDetection != aaOptions.edgeDetection || options.aa.quality != aaOptions.quality) {
			reloadPost = true;
			reloadSmaa = true;
		}

		options.aa = aaOptions;

		if (reloadPost) Gfxa.POST_PIPELINE.Reload();
		if (reloadSmaa) {
			Gfxa.SMAA_BLENDING_PIPELINE.Reload();
			Gfxa.SMAA_EDGE_DETECTION_PIPELINE.Reload();
		}
		
		// Write
		options.Write();
		Meteorite.INSTANCE.connection?.Send(scope ClientSettingsC2SPacket());
	}

	protected override void RenderImpl() {
		Meteorite me = Meteorite.INSTANCE;

		ImGuiCacti.Separator("General");

		ImGui.Checkbox("VSync", &vsync);
		ImGui.SliderInt("Render Distance", &renderDistance, 2, 32);
		ImGui.SliderFloat("FOV", &me.options.fov, 10, 170, "%.0f");
		ImGui.SliderFloat("Mouse Sensitivity", &me.options.mouseSensitivity, 0.1f, 2);
		
		ImGuiCacti.Separator("Ambient Occlusion");

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

		ImGuiCacti.Separator("Anti Aliasing");
		
		ImGui.Checkbox("Enabled", &aaOptions.enabled);
		ImGuiCacti.Combo("Edge Detection", ref aaOptions.edgeDetection);
		ImGuiCacti.Combo("Quality", ref aaOptions.quality);

		ImGuiCacti.Separator("Other");

		ImGui.Checkbox("Chunk Boundaries", &me.options.chunkBoundaries);

		ImGuiCacti.Separator();

		float spacing = ImGui.GetStyle().ItemSpacing.x;
		float width = ImGui.GetWindowContentRegionMax().x / 3 - spacing;

		if (ImGui.Button("Disconnect", .(width, 0))) {
			Gfx.RunOnNewFrame(new () => {
				Text text = .Of("Disconnected");
				me.Disconnect(text);

				delete text;
			});
		}

		ImGui.SameLine();
		if (ImGui.Button("Apply", .(width, 0))) {
			Apply();
			Load();
		}

		ImGui.SameLine();
		if (ImGui.Button("Apply & Close", .(width, 0))) {
			Meteorite.INSTANCE.Screen = null;
		}
	}
}