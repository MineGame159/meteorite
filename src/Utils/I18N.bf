using System;
using System.Collections;

namespace Meteorite {
	static class I18N {
		private static Dictionary<String, String> translations = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public static void Load() {
			Meteorite.INSTANCE.resources.ReadJsons("lang/en_us.json", scope (json) => {
				for (let pair in json.AsObject) {
					String str = pair.value.AsString;
					str.Replace("%s", "{}");

					if (translations.ContainsKey(pair.key)) {
						let (key, value) = translations.GetAndRemove(pair.key).Get();

						delete key;
						delete value;
					}

					translations[new .(pair.key)] = new .(str);
				}

				json.Dispose();
			});
		}

		public static void Translate(String key, String str, params Object[] args) {
			String translation = translations.GetValueOrDefault(key);
			if (translation != null) str.AppendF(translation, params args);
		}
	}
}