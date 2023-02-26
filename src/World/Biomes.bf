using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

static class Biomes {
	public static Biome VOID;
	
	[Tracy.Profile]
	public static void Register() {
		JsonTree tree = Meteorite.INSTANCE.resources.ReadJson("data/biomes.json");
		Json json = tree.root;

		BuiltinRegistries.BIOMES.Parse(json, scope (key, id, json) => {
			Biome biome = Parse(key, id, json);

			if (key.Path == "the_void") VOID = biome;

			return biome;
		});

		delete tree;
	}

	public static Biome Parse(ResourceKey key, int32 id, Json json) {
		Json effects = json["effects"];

		return new .(
			key,
			id,
			(.) json["temperature"].AsNumber,
			(.) json["downfall"].AsNumber,
			.((int32) effects["water_color"].AsNumber),
			.((int32) effects["sky_color"].AsNumber),
			.((int32) effects["fog_color"].AsNumber)
		);
	}

	public static Biome Parse(ResourceKey key, int32 id, Tag tag) {
		Tag effects = tag["effects"];

		return new .(
			key,
			id,
			tag["temperature"].AsFloat,
			tag["downfall"].AsFloat,
			.(effects["water_color"].AsInt),
			.(effects["sky_color"].AsInt),
			.(effects["fog_color"].AsInt)
		);
	}
}