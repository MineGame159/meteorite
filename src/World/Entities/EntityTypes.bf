using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite{
	static class EntityTypes {
		public static Dictionary<int, EntityType> ENTITY_TYPES = new .() ~ delete _;

		public static EntityType PLAYER;
		public static EntityType SALMON;

		public static void Register() {
			Json json = Meteorite.INSTANCE.resources.ReadJson("data/entities.json");

			for (Json e in json.AsArray) {
				EntityType type = new .(
					e["id"].AsString.Substring(10),
					Enum.Parse<EntityGroup>(e["group"].AsString, true),
					e["width"].AsNumber,
					e["height"].AsNumber
				);

				Registry.ENTITY_TYPES.Register(type.id, type);
				ENTITY_TYPES[(.) e["raw_id"].AsNumber] = type;

				if (type.id == "player") PLAYER = type;
				else if (type.id == "salmon") SALMON = type;
			}

			json.Dispose();
		}
	}
}