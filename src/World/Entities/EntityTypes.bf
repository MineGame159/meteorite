using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

static class EntityTypes {
	public static EntityType PLAYER;
	public static EntityType SALMON;
	
	[Tracy.Profile]
	public static void Register() {
		JsonTree tree = Meteorite.INSTANCE.resources.ReadJson("data/entity_types.json");

		BuiltinRegistries.ENTITY_TYPES.Parse(tree.root, scope (key, id, json) => {
			EntityType type = new .(
				key,
				id,
				Enum.Parse<EntityGroup>(json["group"].AsString, true),
				json["width"].AsNumber,
				json["height"].AsNumber
			);

			if (type.Key.Path == "player") PLAYER = type;
			else if (type.Key.Path == "salmon") SALMON = type;

			return type;
		});

		delete tree;
	}
}