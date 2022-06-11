using System;

namespace Meteorite {
	static class TextUtils {
		public static void ToString(Json json, String str) {
			if (!json.IsObject) {
				Log.Error("Invalid text");
				return;
			}

			ToStringComponent(json, str);
		}

		private static void ToStringComponent(Json json, String str) {
			if (json.IsString) {
				str.Append(json.AsString);
				return;
			}

			if (json.Contains("text")) str.Append(json["text"].AsString);
			else if (json.Contains("translate")) {
				Object[] args = null;

				if (json.Contains("with")) {
					let with = json["with"].AsArray;
					args = new Object[with.Count];

					for (int i < with.Count) {
						String s = new .();
						ToStringComponent(with[i], s);
						args[i] = s;
					}
				}

				I18N.Translate(json["translate"].AsString, str, params args);
				if (args != null) DeleteContainerAndItems!(args);
			}

			if (json.Contains("extra")) {
				for (Json e in json["extra"].AsArray) {
					ToStringComponent(e, str);
				}
			}
		}
	}
}