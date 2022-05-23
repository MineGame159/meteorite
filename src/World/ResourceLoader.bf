using System;
using System.IO;
using System.Collections;

using stb_image;

namespace Meteorite {
	class ResourceLoader {
		private List<String> locations = new .() ~ DeleteContainerAndItems!(_);
		private stbi.stbi_io_callbacks stbiCallbacks;

		public this() {
			locations.Add(new .("assets/minecraft"));
			locations.Add(new .("assets/meteorite"));

			for (String pack in Meteorite.INSTANCE.options.resourcePacks) {
				String path = new $"run/resourcepacks/{pack}/assets/minecraft";
				
				if (Directory.Exists(path)) locations.Add(path);
				else delete path;
			}

			stbiCallbacks.read = => StbiRead;
			stbiCallbacks.skip = => StbiSkip;
			stbiCallbacks.eof = => StbiEof;
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

		public bool ReadString(StringView path, String buffer) {
			FileStream fs = scope .();
			if (!GetStream(path, fs)) return false;

			StreamReader reader = scope .(fs);
			reader.ReadToEnd(buffer);

			return true;
		}

		public Image ReadImageInfo(StringView path) {
			String path2 = scope $"textures/{path}";
			FileStream fs = scope .();
			if (!GetStream(path2, fs)) return null;

			int32 width = 0, height = 0, comp = 0;
			stbi.stbi_info_from_callbacks(&stbiCallbacks, Internal.UnsafeCastToPtr(fs), &width, &height, &comp);

			return new .(width, height, comp, null, false);
		}

		public Image ReadImage(StringView path) {
			String path2 = scope $"textures/{path}";
			FileStream fs = scope .();
			if (!GetStream(path2, fs)) return null;

			int32 width = 0, height = 0, comp = 0;
			uint8* data = stbi.stbi_load_from_callbacks(&stbiCallbacks, Internal.UnsafeCastToPtr(fs), &width, &height, &comp, 4);

			return new .(width, height, comp, data, true);
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

		private static int32 StbiRead(void* user, uint8* data, int32 size) {
			FileStream fs = (.) Internal.UnsafeCastToObject(user);
			return (.) fs.TryRead(.(data, size)).Value;
		}

		private static void StbiSkip(void* user, int32 n) {
			FileStream fs = (.) Internal.UnsafeCastToObject(user);
			fs.Skip(n);
		}

		private static bool StbiEof(void* user) {
			FileStream fs = (.) Internal.UnsafeCastToObject(user);
			return fs.IsEmpty;
		}
	}
}