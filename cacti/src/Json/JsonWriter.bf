using System;

namespace Cacti.Json;

class JsonWriter {
	private String str;

	private bool indent;
	private int depth;

	[AllowAppend]
	private this(String str, bool indent) {
		this.str = str;
		this.indent = indent;
	}

	public static void Write(Json json, String str, bool indent = false) {
		scope Self(str, indent).Write(json);
	}

	private void Write(Json json) {
		switch (json.Type) {
		case .Null:		str.Append("null");
		case .Bool:		str.Append(json.AsBool ? "true" : "false");
		case .Number:	json.AsNumber.ToString(str);
		case .String:	str.Append('"'); Escape(json.AsString, str); str.Append('"');
		case .Array:	WriteArray(json);
		case .Object:	WriteObject(json);
		}
	}

	private void WriteArray(Json json) {
		int i = 0;
		bool newLines = indent ? !HasOnlyPrimitives(json) : false;

		if (newLines || json.AsArray.IsEmpty) str.Append('[');
		else str.Append("[ ");

		depth++;

		for (let element in json.AsArray) {
			if (i++ > 0) {
				if (indent) {
					if (newLines) str.Append(',');
					else str.Append(", ");
				}
				else str.Append(',');
			}
			if (newLines) EndLine();

			Write(element);
		}

		depth--;
		if (i > 0 && newLines) EndLine();

		if (newLines || i == 0) str.Append(']');
		else str.Append(" ]");
	}

	private void WriteObject(Json json) {
		int i = 0;

		str.Append('{');
		depth++;

		for (let (name, element) in json.AsObject) {
			if (i++ > 0) str.Append(',');
			EndLine();

			str.Append('"');
			str.Append(name);
			str.Append(indent ? "\": " : "\":");

			Write(element);
		}

		depth--;
		if (i > 0) EndLine();
		str.Append('}');
	}

	private void EndLine() {
		if (!indent) return;

		str.Append('\n');

		for (int i < depth) {
			str.Append('\t');
		}
	}

	private static bool HasOnlyPrimitives(Json json) {
		for (let element in json.AsArray) {
			switch (element.Type) {
			case .String, .Array, .Object:	return false;
			default:
			}
		}

		return true;
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