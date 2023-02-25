using System;
using System.Diagnostics;

namespace Cacti.Json;

class JsonWriter {
	private const int MAX_DEPTH = 16;

	private BaseWriter writer;
	private bool indent;

	private append String nextValueName = .();	
	private Container[MAX_DEPTH] containers;
	private int containerCount;

	[AllowAppend]
	public this(String string, bool indent) {
		BaseWriter writer = append StringWriter(string);

		this.writer = writer;
		this.indent = indent;
	}

	public this(BaseWriter writer, bool indent) {
		this.writer = writer;
		this.indent = indent;
	}

	public static void Write(Json value, String string, bool indent) {
		JsonWriter writer = scope .(string, indent);
		writer.Json(value);
	}

	public void SetNextValueName(StringView name) {
		nextValueName.Set(name);
	}

	public void Null(StringView name) {
		BeforeValue(name, false);
		writer.Write("null");
	}

	public void Null() => Null("");

	public void Bool(StringView name, bool value) {
		BeforeValue(name, false);
		writer.Write(value ? "true" : "false");
	}
	
	public void Bool(bool value) => Bool("", value);

	public void Number<T>(StringView name, T value) where T : operator explicit Double {
		BeforeValue(name, false);
		writer.Write(value.ToString(.. scope .()));
	}

	public void Number<T>(T value) where T : operator explicit Double => Number("", value);

	public void String(StringView name, StringView value) {
		BeforeValue(name, false);
		writer.Write('"');

		for (char8 char in value) {
			switch (char) {
			case '\'': writer.Write(@"'");
		    case '\"': writer.Write("\\\"");
		    case '\\': writer.Write(@"\\");
		    case '\0': writer.Write(@"\0");
		    case '\a': writer.Write(@"\a");
		    case '\b': writer.Write(@"\b");
		    case '\f': writer.Write(@"\f");
		    case '\n': writer.Write(@"\n");
		    case '\r': writer.Write(@"\r");
		    case '\t': writer.Write(@"\t");
		    case '\v': writer.Write(@"\v");
		    default:
		    	if (char < (char8) 32) {
		    		writer.Write(@"\x");
		    		writer.Write(String.[Friend]sHexUpperChars[((int)char>>4) & 0xF]);
		    		writer.Write(String.[Friend]sHexUpperChars[(int)char & 0xF]);
		    		break;
		    	}

		    	writer.Write(char);
			}
		}

		writer.Write('"');
	}

	public void String(StringView value) => String("", value);

	public void String<T>(StringView name, T value) => String(name, (StringView) value.ToString(.. scope .()));

	public void String<T>(T value) => String("", value.ToString(.. scope .()));

	public ArrayWriter Array(StringView name = "") {
		BeforeValue(name, true);

		writer.Write('[');
		containers[containerCount++] = .(.Array);
		
		return [Friend].(this);
	}

	public void EndArray() {
		if (containers[--containerCount].valueCount > 0) EndLine();
		writer.Write(']');
	}

	public ObjectWriter Object(StringView name = "") {
		BeforeValue(name, true);

		writer.Write('{');
		containers[containerCount++] = .(.Object);

		return [Friend].(this);
	}

	private void EndObject() {
		if (containers[--containerCount].valueCount > 0) EndLine();
		writer.Write('}');
	}

	public void Json(StringView name, Json value) {
		switch (value.Type) {
		case .Null:		Null(name);
		case .Bool:		Bool(name, value.AsBool);
		case .Number:	Number(name, value.AsNumber);
		case .String:	String(name, value.AsString);

		case .Array:
			using (Array(name)) {
				for (let child in value.AsArray) {
					Json(child);
				}
			}

		case .Object:
			using (Object(name)) {
				for (let (childName, child) in value.AsObject) {
					Json(childName, child);
				}
			}
		}
	}

	public void Json(Json value) => Json("", value);

	private void BeforeValue(StringView name, bool isContainer) {
		var name;

		Debug.Assert(isContainer || containerCount != 0, "Before writing a JSON value you need to begin writing either an array or an object");

		if (!nextValueName.IsEmpty) {
			name = nextValueName;
			nextValueName.Clear();
		}

		if (containerCount > 0) {
			var container = ref containers[containerCount - 1];

			if (container.valueCount > 0) writer.Write(',');
			EndLine();

			if (container.type == .Object) {
				Debug.Assert(!name.IsEmpty, "Cannot write a JSON value inside an object without a name");
	
				writer.Write('"');
				writer.Write(name);

				if (indent) writer.Write("\": ");
				else writer.Write("\":");
			}

			container.valueCount++;
		}
	}

	private void EndLine() {
		if (!indent) return;

		writer.Write('\n');

		for (int i < containerCount) {
			writer.Write('\t');
		}
	}

	public struct ArrayWriter : IDisposable {
		private JsonWriter writer;

		private this(JsonWriter writer) {
			this.writer = writer;
		}

		public void Dispose() => writer.EndArray();
	}

	public struct ObjectWriter : IDisposable {
		private JsonWriter writer;

		private this(JsonWriter writer) {
			this.writer = writer;
		}

		public void Dispose() => writer.EndObject();
	}

	enum ContainerType {
		Array,
		Object
	}

	struct Container {
		public ContainerType type;
		public int valueCount;

		public this(ContainerType type) {
			this.type = type;
			this.valueCount = 0;
		}
	}
}