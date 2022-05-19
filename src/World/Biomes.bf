using System;
using System.Collections;

namespace Meteorite {
	static class Biomes {
		public static Biome[] BIOMES ~ DeleteContainerAndItems!(_);

		public static Biome VOID;

		public static void Register() {
			Json json = Meteorite.INSTANCE.resources.ReadJson("data/biomes.json");

			BIOMES = new .[json.AsArray.Count];

			for (Json e in json.AsArray) {
				int32 id = (.) e["raw_id"].AsNumber;

				float temperature = (.) e["temperature"].AsNumber;
				float downfall = (.) e["downfall"].AsNumber;
				Color waterColor = .((int32) e["water_color"].AsNumber);
				Color skyColor = .((int32) e["sky_color"].AsNumber);
				Color fogColor = .((int32) e["fog_color"].AsNumber);

				BIOMES[id] = new .(temperature, downfall, waterColor, skyColor, fogColor);

				if (id == 0) VOID = BIOMES[id];
			}

			json.Dispose();
		}
	}
}