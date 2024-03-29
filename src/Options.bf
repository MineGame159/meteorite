using System;
using System.IO;
using System.Collections;

using Cacti;
using Cacti.Json;
using Cacti.Graphics;

namespace Meteorite;

enum AO {
	case None;
	case Vanilla;
	case SSAO;
	case Both;

	public bool HasVanilla => this == .Vanilla || this == .Both;
	public bool HasSSAO => this == .SSAO || this == .Both;
}

enum AAEdgeDetection {
	Fast,
	Fancy
}

enum AAQuality {
	Fast,
	Balanced,
	Fancy
}

struct AAOptions {
	public bool enabled = false;
	public AAEdgeDetection edgeDetection = .Fast;
	public AAQuality quality = .Balanced;

	public void ToJson(JsonWriter json) {
		using (json.Object()) {
			json.Bool("enabled", enabled);

			json.String("edge_detection", edgeDetection);
			json.String("quality", quality);
		}
	}

	public void FromJson(Json json) mut {
		enabled = json.GetBool("enabled");
		edgeDetection = Enum.Parse<AAEdgeDetection>(json.GetString("edge_detection"), true).Get(.Fast);
		quality = Enum.Parse<AAQuality>(json.GetString("quality"), true).Get(.Balanced);
	}
}

class Options {
	public bool chunkBoundaries = false;

	private bool vsync_ = true;

	public int renderDistance = 6;
	public float fov = 75;
	public float mouseSensitivity = 1;

	public AO ao = .Vanilla;

	public AAOptions aa = .();

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

		JsonTree tree = JsonParser.Parse(s);
		Json json = tree.root;

		vsync = json.GetBool("vsync", true);

		renderDistance = (.) json.GetInt("render_distance", 6);
		fov = (.) json.GetDouble("fov", 75);
		mouseSensitivity = (.) json.GetDouble("mouse_sensitivity", 1);

		ao = Enum.Parse<AO>(json.GetString("ao", "vanilla"), true);

		aa.FromJson(json["anti_aliasing"]);

		if (json.Contains("resource_packs")) {
			for (let j in json["resource_packs"].AsArray) {
				resourcePacks.Add(new .(j.AsString));
			}
		}

		delete tree;
	}

	public void Write() {
		FileStream fs = scope .();

		if (fs.Create("run/options.json", .Write) case .Err) {
			Log.Error("Failed to save options to 'run/options.json'");
			return;
		}

		JsonWriter json = scope .(scope MyStreamWriter(fs), true);

		using (json.Object()) {
			json.Bool("vsync", vsync);

			json.Number("render_distance", renderDistance);
			json.Number("fov", fov);
			json.Number("mouse_sensitivity", mouseSensitivity);

			json.String("ao", ao);

			json.SetNextValueName("anti_aliasing");
			aa.ToJson(json);

			using (json.Array("resource_packs")) {
				for (String resourcePack in resourcePacks) {
					json.String(resourcePack);
				}
			}
		}
	}
}