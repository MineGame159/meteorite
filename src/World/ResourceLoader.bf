using System;
using System.IO;
using System.Collections;

using Cacti;

namespace Meteorite {
	class ResourceLoader {
		private List<String> locations = new .() ~ DeleteContainerAndItems!(_);

		public this() {
			locations.Add(new .("assets/minecraft"));
			locations.Add(new .("assets/meteorite"));

			for (String pack in Meteorite.INSTANCE.options.resourcePacks) {
				String path = new $"run/resourcepacks/{pack}/assets/minecraft";
				
				if (Directory.Exists(path)) locations.Add(path);
				else delete path;
			}
		}

		private bool GetStream(StringView path, FileStream fs) {
			for (int i = locations.Count - 1; i >= 0; i--) {
				String fullPath = scope $"{locations[i]}/{path}";
				if (fs.Open(fullPath, .Read) == .Ok) return true;
			}

			return false;
		}

		private void GetPath(StringView path, String buffer) {
			for (int i = locations.Count - 1; i >= 0; i--) {
				String fullPath = scope $"{locations[i]}/{path}";

				if (File.Exists(fullPath)) {
					buffer.Append(fullPath);
					break;
				}
			}
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

		public bool ReadString(StringView path, String buffer) {
			FileStream fs = scope .();
			if (!GetStream(path, fs)) return false;

			StreamReader reader = scope .(fs);
			reader.ReadToEnd(buffer);

			return true;
		}

		public bool ReadLines(StringView path, delegate void(StringView) callback) {
			FileStream fs = scope .();
			if (!GetStream(path, fs)) return false;

			StreamReader reader = scope .(fs);
			for (let line in reader.Lines) callback(line);

			return true;
		}

		public Result<ImageInfo> ReadImageInfo(StringView path) {
			String path2 = GetPath(scope $"textures/{path}", .. scope .());
			if (path2 == "") return .Err;

			return ImageInfo.Read(path2);
		}

		public Result<Image> ReadImage(StringView path) {
			String path2 = GetPath(scope $"textures/{path}", .. scope .());
			if (path2 == "") return .Err;

			return Image.Read(path2);
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