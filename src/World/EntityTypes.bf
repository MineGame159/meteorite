using System;
using System.Collections;

namespace Meteorite{
	static class EntityTypes {
		public static Dictionary<int, EntityType> ENTITY_TYPES = new .() ~ delete _;

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
			}

			json.Dispose();
		}
	}
}