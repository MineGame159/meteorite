using System;
using System.Collections;

namespace Meteorite {
	static class Biomes {
		public static Dictionary<int32, Biome> BIOMES = new .() ~ DeleteDictionaryAndValues!(_);

		public static Biome VOID;

		public static void Register() {
			Json json = JsonParser.ParseFile("assets/biomes.json");

			for (Json e in json.AsArray) {
				int32 id = (.) e["raw_id"].AsNumber;

				float temperature = (.) e["temperature"].AsNumber;
				float downfall = (.) e["downfall"].AsNumber;
				Color waterColor = .((int32) e["water_color"].AsNumber);

				BIOMES[id] = new .(temperature, downfall, waterColor);

				if (id == 0) VOID = BIOMES[id];
			}

			json.Dispose();
		}
	}
}