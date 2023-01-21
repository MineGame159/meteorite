using System;
using System.IO;
using System.Collections;

using Cacti;

namespace Meteorite {
	enum AO {
		case None;
		case Vanilla;
		case SSAO;
		case Both;

		public bool HasVanilla => this == .Vanilla || this == .Both;
		public bool HasSSAO => this == .SSAO || this == .Both;
	}

	class Options {
		public bool chunkBoundaries = false;

		private bool vsync_ = true;

		public int32 renderDistance = 6;
		public float fov = 75;
		public float mouseSensitivity = 1;

		public AO ao = .Vanilla;
		public bool fxaa = false;

		public List<String> resourcePacks = new .() ~ DeleteContainerAndItems!(_);

		public bool vsync {
			get => vsync_;
			set {
				if (vsync_ != value && Gfx.Swapchain != null) {
					Gfx.Swapchain.vsync = value;
					Meteorite.INSTANCE.Execute(new () => Gfx.Swapchain.Recreate(Meteorite.INSTANCE.window.size)); // This callback ensures it runs outside of any rendering
				}

				vsync_ = value;
			}
		}

		public this() {
			if (!File.Exists("run/options.json")) {
				Write();
				return;
			}

			FileStream s = scope .();
			if (s.Open("run/options.json") case .Err) {
				Log.Error("Failed to read options.json file");
				return;
			}

			Json json = JsonParser.Parse(s);

			vsync = json.GetBool("vsync", true);

			renderDistance = (.) json.GetInt("render_distance", 6);
			fov = (.) json.GetDouble("fov", 75);
			mouseSensitivity = (.) json.GetDouble("mouse_sensitivity", 1);

			ao = Enum.Parse<AO>(json.GetString("ao", "vanilla"), true);
			fxaa = json.GetBool("fxaa", false);

			if (json.Contains("resource_packs")) {
				for (let j in json["resource_packs"].AsArray) {
					resourcePacks.Add(new .(j.AsString));
				}
			}

			json.Dispose();
		}

		public void Write() {
			Json json = .Object();

			json["vsync"] = .Bool(vsync);

			json["render_distance"] = .Number(renderDistance);
			json["fov"] = .Number(fov);
			json["mouse_sensitivity"] = .Number(mouseSensitivity);

			json["ao"] = .String(ao.ToString(.. scope .()));
			json["fxaa"] = .Bool(fxaa);

			Json resourcePacksJson = json["resource_packs"] =.Array();
			for (let resourcePack in resourcePacks) {
				resourcePacksJson.Add(.String(resourcePack));
			}

			String str = JsonWriter.Write(json, .. scope .());
			File.WriteAllText("run/options.json", str);

			json.Dispose();
		}
	}
}