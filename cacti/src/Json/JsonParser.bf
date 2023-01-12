using System;
using System.IO;

namespace Cacti {
	class JsonParser {
		private Stream s;

		private String str = new .() ~ delete _;
		private bool isKey;
		
		private Json root, element;

		private this(Stream s) {
			this.s = s;
		}

		public static Json Parse(Stream s) {
			return scope JsonParser(s).Parse();
		}

		public static Json ParseString(StringView s) {
			return Parse(scope StringStream(s, .Reference));
		}

		private Json Parse() {
			SkipWhitespace();
			ParseValue();

			return root;
		}

		private void ParseValue() {
			if (s.Peek<char8>() case .Ok(let c)) {
				switch (c) {
				case '{': ParseObject();
				case '[': ParseArray();
				case '"': ParseString();
				case 't': ParseBool();
				case 'f': ParseBool();
				case 'n': ParseNull();
				default:  ParseNumber();
				}
			}
		}

		private void ParseObject() {
			s.Skip(1);
			SkipWhitespace();

			String key = scope .();

			Json object = .Object();
			if (root.IsNull) root = object;

			for (;;) {
				if (s.Peek<char8>() == '}') break;

				isKey = true;
				ParseString();
				SkipWhitespace();
				key.Set(str);
				isKey = false;

				Consume(':');

				ParseValue();
				SkipWhitespace();

				object[key] = element;

				if (s.Peek<char8>() == '}') break;
				else Consume(',');
			}

			element = object;

			Consume('}');
		}

		private void ParseArray() {
			s.Skip(1);
			SkipWhitespace();

			Json array = .Array();
			if (root.IsNull) root = array;

			for (;;) {
				if (s.Peek<char8>() == ']') break;

				ParseValue();
				SkipWhitespace();

				array.Add(element);

				if (s.Peek<char8>() == ']') break;
				else Consume(',');
			}

			element = array;

			Consume(']');
		}

		private void ParseString() {
			Consume('"');
			str.Clear();

			char8 lastC = '\0';

			for (;;) {
				char8 c = s.Peek<char8>();

				if (c == '"' && lastC != '\\') break;
				else {
					str.Append(c);
					s.Skip(1);
				}

				if (c == '\\' && lastC == '\\') c = '\0';
				lastC = c;
			}
			
			if (!isKey) element = .String(str);

			Consume('"');
		}

		private void ParseBool() {
			char8 c = s.Peek<char8>();
			s.Skip(1);

			if (c == 't') {
				Consume('r');
				Consume('u');
				Consume('e');

				element = .Bool(true);
			}
			else {
				Consume('a');
				Consume('l');
				Consume('s');
				Consume('e');

				element = .Bool(false);
			}
		}

		private void ParseNull() {
			Consume('n');
			Consume('u');
			Consume('l');
			Consume('l');

			element = .Null();
		}

		private void ParseNumber() {
			String str = scope .();

			for (;;) {
				char8 c = s.Peek<char8>();

				if (c.IsNumber || c == '-' || c == '.') {
					str.Append(c);
					s.Skip(1);
				}
				else break;
			}

			element = .Number(double.Parse(str));
		}

		private void SkipWhitespace() {
			while (s.Peek<char8>() case .Ok(let c)) {
				if (c.IsWhiteSpace) s.Skip(1);
				else break;
			}
		}

		private void Consume(char8 expected) {
			if (let c = s.Peek<char8>()) {
				if (c == expected) {
					s.Skip(1);
					SkipWhitespace();
					return;
				}
			}

			Log.Error("Invalid json");
		}
	}
}