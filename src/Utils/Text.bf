using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite {
	class Text {
		private String content ~ delete _;
		private Color color;

		private List<Text> siblings ~ DeleteContainerAndItems!(_);

		private this(StringView content, Color color, List<Text> siblings) {
			this.content = new .(content);
			this.color = color;
			this.siblings = siblings;
		}

		public void Visit(delegate void(StringView, Color) visitor) {
			visitor(content, color);

			if (siblings != null) {
				for (Text sibling in siblings) sibling.Visit(visitor);
			}
		}

		public Text Copy() {
			List<Text> siblings = null;

			if (this.siblings != null) {
				siblings = new .(this.siblings.Count);

				for (Text sibling in this.siblings) siblings.Add(sibling.Copy());
			}

			return new .(content, color, siblings);
		}

		public override void ToString(String str) {
			str.Append(content);

			if (siblings != null) {
				for (Text sibling in siblings) sibling.ToString(str);
			}
		}

		public static Text Of(StringView string) => new .(string, .WHITE, null);

		public static Text Parse(Json json) {
			if (!json.IsString && !json.IsObject) {
				Log.Error("Invalid text");
				return null;
			}

			return ToText(json);
		}

		public static Result<Color> ParseColor(StringView raw) {
			if (raw.StartsWith('#')) {
				Color color = .(int32.Parse(raw[1...], .HexNumber));
				color.a = 255;

				return color;
			}
			else if (raw != "reset") {
				return DyeColor.Get(raw);
			}

			return .Err;
		}

		private static Text ToText(Json json) {
			if (json.IsString) return .Of(json.AsString);

			// Color
			Color color = .WHITE;

			if (json.Contains("color")) {
				Result<Color> c = ParseColor(json["color"].AsString);
				if (c case .Ok(let val)) color = val;
			}

			// Content
			String rawContent;

			if (json.Contains("text")) rawContent = scope:: .(json["text"].AsString);
			else if (json.Contains("translate")) {
				Object[] args = null;

				if (json.Contains("with")) {
					let with = json["with"].AsArray;
					args = new Object[with.Count];

					for (int i < with.Count) {
						String s = new .();

						Text text = .Parse(with[i]);
						if (text == null) {
							delete s;
							DeleteContainerAndItems!(args);
							return null;
						}

						text.ToString(s);
						delete text;

						args[i] = s;
					}
				}

				rawContent = scope:: .();
				I18N.Translate(json["translate"].AsString, rawContent, params args);
				if (args != null) DeleteContainerAndItems!(args);
			}
			else {
				Log.Error("Unknown text contents");
				return null;
			}

			String content = scope .();
			Decode(rawContent, content);

			// Siblings
			List<Text> siblings = new .();

			if (json.Contains("extra")) {
				for (let j in json["extra"].AsArray) {
					Text text = ToText(j);
					if (text != null) siblings.Add(text);
				}
			}

			return new .(content, color, siblings);
		}

		private static void Decode(String str, String buf) {
			bool a = false;
			String chars = scope .(4);

			for (let char in str.RawChars) {
				if (char == '\\' && str.Length > @char.Index + 1 && str[@char.Index + 1] == 'u') {
					a = true;
					continue;
				}

				if (a) {
					if (char == 'u') continue;
					chars.Append(char);

					if (chars.Length == 4) {
						let result = int32.Parse(chars, .HexNumber);
						if (result case .Ok(let val)) buf.Append((char32) val);

						chars.Clear();
						a = false;
					}

					continue;
				}

				buf.Append(char);
			}
		}
	}
}