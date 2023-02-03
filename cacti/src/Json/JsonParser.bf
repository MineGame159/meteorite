using System;
using System.IO;

namespace Cacti.Json;

class JsonParser {
	private JsonLexer lexer ~ delete _;

	private JsonToken current, next;
	private Json json;

	private this(Stream stream) {
		this.lexer = new .(stream);
	}

	public static Result<Json> Parse(Stream stream) => scope Self(stream).Parse();

	public static Result<Json> Parse(StringView string) => scope Self(scope SpanMemoryStream(.((.) string.Ptr, string.Length))).Parse();

	private Result<Json> Parse() {
		Handle!(Advance());
		Handle!(Advance());

		switch (current) {
		case .LeftBracket:	return ParseArray();
		case .LeftBrace:	return ParseObject();
		default:			return .Err;
		}
	}

	private Result<Json> ParseElement() {
		mixin Return(Json json) {
			Handle!(Advance());
			return json;
		}

		switch (current) {
		case .Null:					Return!(Json.Null());
		case .True:					Return!(Json.Bool(true));
		case .False:				Return!(Json.Bool(false));
		case .Number(let value):	Return!(Json.Number(value));
		case .String(let value):	Return!(Json.String(value));
		case .LeftBracket:			return Handle!(ParseArray());
		case .LeftBrace:			return Handle!(ParseObject());
		default:					return .Err;
		}
	}

	private Result<Json> ParseArray() {
		Handle!(Advance());
		Json json = .Array();

		defer {
			if (@return == .Err) {
				json.Dispose();
			}
		}

		while (current != .RightBracket) {
			Json element = Handle!(ParseElement());
			json.Add(element);

			if (current != .RightBracket) Expect!(JsonToken.Comma);
		}

		Expect!(JsonToken.RightBracket);

		return json;
	}

	private Result<Json> ParseObject() {
		Handle!(Advance());
		Json json = .Object();

		defer {
			if (@return == .Err) {
				json.Dispose();
			}
		}

		while (current != .RightBrace) {
			String name = scope .(32);

			if (current case .String(let value)) {
				name.Set(value);
				Handle!(Advance());
			}
			else return .Err;

			Expect!(JsonToken.Colon);

			Json element = Handle!(ParseElement());
			json[name] = element;

			if (current != .RightBrace) Expect!(JsonToken.Comma);
		}

		Expect!(JsonToken.RightBrace);

		return json;
	}

	private mixin Expect(JsonToken token) {
		if (current != token) {
			return .Err;
		}

		Handle!(Advance());
	}

	private Result<void> Advance() {
		current = next;

		switch (lexer.GetNext()) {
		case .Ok(let val):
			next = val;
			return .Ok;
		case .Err(let err):
			return .Err;
		}
	}

	private mixin Handle<T>(Result<T> result) {
		if (result == .Err) {
			return .Err;
		}

		result.Value
	}
}