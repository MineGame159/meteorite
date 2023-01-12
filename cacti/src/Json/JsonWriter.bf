using System;

namespace Cacti {
	static class JsonWriter {
		public static void Write(Json json, String buffer) {
			switch (json.type) {
			case .String:
				buffer.Append('"');
				Escape(json.AsString, buffer);
				buffer.Append('"');
			case .Object: WriteObject(json, buffer);
			case .Array:  WriteArray(json, buffer);
			default:      json.ToString(buffer);
			}
		}

		private static void WriteObject(Json json, String buffer) {
			buffer.Append('{');

			int i = 0;
			for (let field in json.AsObject) {
				if (i > 0) buffer.Append(',');

				buffer.Append('"');
				Escape(field.key, buffer);
				buffer.Append("\":");
				Write(field.value, buffer);

				i++;
			}

			buffer.Append('}');
		}

		private static void WriteArray(Json json, String buffer) {
			buffer.Append('[');

			int i = 0;
			for (let item in json.AsArray) {
				if (i > 0) buffer.Append(',');

				Write(item, buffer);

				i++;
			}

			buffer.Append(']');
		}

		private static void Escape(String str, String outString) {
			for (int i < str.Length) {
				char8 c = str.Ptr[i];

				switch (c) {
				case '\'': outString.Append(@"'");
			    case '\"': outString.Append("\\\"");
			    case '\\': outString.Append(@"\\");
			    case '\0': outString.Append(@"\0");
			    case '\a': outString.Append(@"\a");
			    case '\b': outString.Append(@"\b");
			    case '\f': outString.Append(@"\f");
			    case '\n': outString.Append(@"\n");
			    case '\r': outString.Append(@"\r");
			    case '\t': outString.Append(@"\t");
			    case '\v': outString.Append(@"\v");
			    default: 
			    	if (c < (char8) 32) {
			    		outString.Append(@"\x");
			    		outString.Append(String.[Friend]sHexUpperChars[((int)c>>4) & 0xF]);
			    		outString.Append(String.[Friend]sHexUpperChars[(int)c & 0xF]);
			    		break;
			    	}
			    	outString.Append(c);
				}
			}
		}
	}
}