using System;
using System.IO;
using System.Collections;

using stb_image;

namespace Meteorite {
	class ResourceLoader {
		private List<String> locations = new .() ~ DeleteContainerAndItems!(_);

		public this() {
			locations.Add(new .("assets"));

			for (String pack in Meteorite.INSTANCE.options.resourcePacks) {
				String path = new $"run/resourcepacks/{pack}/assets/minecraft";
				
				if (Directory.Exists(path)) locations.Add(path);
				else delete path;
			}
		}

		private bool GetStream(StringView path, FileStream s) {
			for (int i = locations.Count - 1; i >= 0; i--) {
				String fullPath = scope $"{locations[i]}/{path}";
				if (s.Open(fullPath, .Read) == .Ok) return true;
			}

			return false;
		}

		public bool ReadBytes(StringView path, List<uint8> buffer) {
			FileStream fs = scope .();
			if (!GetStream(path, fs)) return false;

			while (true) {
				uint8[4096] data;
				switch (fs.TryRead(.(&data, 4096)))
				{
				case .Ok(let bytes):
					if (bytes == 0) return true;
					buffer.AddRange(.(&data, bytes));
				case .Err:
					return false;
				}
			}
		}

		public Image ReadImage(StringView path) {
			List<uint8> buffer = new .();
			defer delete buffer;

			String path2 = scope $"textures/{path}";
			if (!ReadBytes(path2, buffer)) return null;

			int32 width = 0, height = 0, comp = 0;
			uint8* data = stbi.stbi_load_from_memory(buffer.Ptr, (.) buffer.Count, &width, &height, &comp, 4);

			return new .(width, height, comp, data);
		}

		public Result<Json> ReadJson(StringView path) {
			FileStream fs = scope .();
			if (!GetStream(path, fs)) return .Err;

			return JsonParser.Parse(fs);
		}

		public void ReadJsons(StringView path, delegate void(Json json) callback) {
			for (int i < locations.Count) {
				String fullPath = scope $"{locations[i]}/{path}";

				FileStream fs = scope .();
				if (fs.Open(fullPath, .Read) == .Ok) callback(JsonParser.Parse(fs));
			}
		}
	}
}