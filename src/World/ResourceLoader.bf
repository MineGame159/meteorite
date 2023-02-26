using System;
using System.IO;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

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
	
	[Tracy.Profile]
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
	
	[Tracy.Profile]
	public bool ReadString(StringView path, String buffer) {
		FileStream fs = scope .();
		if (!GetStream(path, fs)) return false;

		StreamReader reader = scope .(fs);
		reader.ReadToEnd(buffer);

		return true;
	}
	
	[Tracy.Profile]
	public bool ReadLines(StringView path, delegate void(StringView) callback) {
		FileStream fs = scope .();
		if (!GetStream(path, fs)) return false;

		StreamReader reader = scope .(fs);
		for (let line in reader.Lines) callback(line);

		return true;
	}
	
	[Tracy.Profile]
	public Result<ImageInfo> ReadImageInfo(StringView path) {
		String path2 = GetPath(scope $"textures/{path}", .. scope .());
		if (path2 == "") return .Err;

		return ImageInfo.Read(path2);
	}
	
	[Tracy.Profile]
	public Result<Image> ReadImage(StringView path, bool flip = false) {
		String path2 = GetPath(scope $"textures/{path}", .. scope .());
		if (path2 == "") return .Err;

		return Image.Read(path2, flip: flip);
	}
	
	[Tracy.Profile]
	public Result<JsonTree> ReadJson(StringView path) {
		FileStream fs = scope .();
		if (!GetStream(path, fs)) return .Err;

		return JsonParser.Parse(fs);
	}
	
	[Tracy.Profile]
	public void ReadJsons(StringView path, delegate void(JsonTree tree) callback) {
		for (int i < locations.Count) {
			String fullPath = scope $"{locations[i]}/{path}";
			FileStream fs = scope .();
			
			if (fs.Open(fullPath, .Read) == .Ok) {
				if (JsonParser.Parse(fs) case .Ok(let val)) {
					callback(val);
				}
			}
		}
	}
}