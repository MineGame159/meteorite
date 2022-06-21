using System;
using System.IO;
using System.Collections;

namespace Meteorite {
	class Options {
		public bool mipmaps = true;
		public bool sortChunks = true;
		public bool chunkBoundaries;
		public float fov = 75;

		public bool ao = true;
		public bool fxaa = false;

		public List<String> resourcePacks = new .() ~ DeleteContainerAndItems!(_);

		public this() {
			StreamReader reader = scope .();
			if (reader.Open("run/options.txt") case .Err) return;

			for (StringView line in reader.Lines) {
				var split = line.Split(':');

				StringView name = split.GetNext();
				StringView value = split.GetNext();

				switch (name) {
				case "resourcePacks": ReadStringList(value, resourcePacks);
				}
			}
		}

		private void ReadStringList(StringView value, List<String> list) {
			let split = value[1...value.Length - 2].Split(',');

			for (StringView pack in split) {
				let name = pack[1...pack.Length - 2];
				if (!name.StartsWith("file/")) continue;

				list.Add(new .(name[5...]));
			}
		}
	}
}