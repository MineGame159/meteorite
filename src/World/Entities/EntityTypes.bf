using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite{
	static class EntityTypes {
		public static EntityType PLAYER;
		public static EntityType SALMON;

		public static void Register() {
			Json json = Meteorite.INSTANCE.resources.ReadJson("data/entity_types.json");

			BuiltinRegistries.ENTITY_TYPES.Parse(json, scope (key, id, json) => {
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

			json.Dispose();
		}
	}
}