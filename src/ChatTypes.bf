using System;

using Cacti;
using Cacti.Json;

namespace Meteorite;

static class ChatTypes {
	public static ChatType[] TYPES ~ DeleteContainerAndItems!(_);
	
	[Tracy.Profile]
	public static void Register() {
		JsonTree tree = Meteorite.INSTANCE.resources.ReadJson("data/chat_types.json");
		Json json = tree.root;

		TYPES = new .[json.AsArray.Count];

		for (let e in json.AsArray) {
			int32 id = (.) e["raw_id"].AsNumber;

			StringView translationKey = e["translation_key"].AsString;
			String[] parameters = new .[e["parameters"].AsArray.Count];
			Color color = .WHITE;

			for (let j in e["parameters"].AsArray) {
				parameters[@j.Index] = new .(j.AsString);
			}

			if (e.Contains("color")) {
				Result<Color> c = Text.ParseColor(json["color"].AsString);
				if (c case .Ok(let val)) color = val;
			}

			TYPES[id] = new .(translationKey, parameters, color);
		}

		delete tree;
	}
}