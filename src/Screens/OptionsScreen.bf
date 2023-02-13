using System;

using Cacti;
using Cacti.Graphics;
using ImGui;

namespace Meteorite;

class OptionsScreen : Screen {
	private Options options = Meteorite.INSTANCE.options;

	private bool vsync;
	private int renderDistance;
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
		
		using (ImGuiOptions opts = .(200)) {
			opts.Checkbox("V-Sync", ref vsync);
			opts.SliderInt("Render Distance", ref renderDistance, 2, 32);
			opts.SliderFloat("FOV", ref me.options.fov, 10, 170, "%.0f");
			opts.SliderFloat("Mouse Sensitivity", ref me.options.mouseSensitivity, 0.1f, 2);
		}
		
		ImGuiCacti.Separator("Ambient Occlusion");

		AO prevAo = me.options.ao;
		using (ImGuiOptions opts = .(200)) {
			if (opts.Combo("Ambient Occlusion", ref me.options.ao)) {
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
		}

		ImGuiCacti.Separator("Anti Aliasing");

		using (ImGuiOptions opts = .(200)) {
			opts.Checkbox("Enabled", ref aaOptions.enabled);
			opts.Combo("Edge Detection", ref aaOptions.edgeDetection);
			opts.Combo("Quality", ref aaOptions.quality);
		}

		ImGuiCacti.Separator("Other");

		using (ImGuiOptions opts = .(200)) {
			opts.Checkbox("Chunk Boundaries", ref me.options.chunkBoundaries);
		}

		ImGuiCacti.Separator();

		using (ImGuiButtons btns = .(3)) {
			if (btns.Button("Disconnect")) {
				me.Execute(new () => {
					Text text = .Of("Disconnected");
					me.Disconnect(text);

					delete text;
				});
			}

			if (btns.Button("Apply")) {
				Apply();
				Load();
			}

			if (btns.Button("Apply & Close")) {
				Meteorite.INSTANCE.Screen = null;
			}
		}
	}
}