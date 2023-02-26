using System;
using System.Collections;

using Cacti;

namespace Meteorite;

static class I18N {
	private static Dictionary<String, String> translations = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

	[Tracy.Profile]
	public static void Load() {
		Meteorite.INSTANCE.resources.ReadJsons("lang/en_us.json", scope (tree) => {
			for (let pair in tree.root.AsObject) {
				String str = scope .()..Set(pair.value.AsString);
				str.Replace("%s", "{}");

				if (translations.ContainsKeyAlt(pair.key)) {
					let (key, value) = translations.GetAndRemoveAlt(pair.key).Get();

					delete key;
					delete value;
				}

				translations[new .(pair.key)] = new .(str);
			}

			delete tree;
		});
	}

	public static void Translate(StringView key, String str, params Object[] args) {
		String translation;

		if (translations.TryGetValueAlt(key, out translation)) {
			str.AppendF(translation, params args);
		}
	}
}