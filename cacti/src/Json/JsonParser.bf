using System;
using System.IO;

namespace Cacti.Json;

class JsonParser {
	private JsonLexer lexer ~ delete _;

	private JsonTree tree;

	private JsonToken current, next;
	private Json json;

	private this(Stream stream) {
		this.lexer = new .(stream);
	}

	public static Result<JsonTree> Parse(Stream stream) => scope Self(stream).Parse();

	public static Result<JsonTree> Parse(StringView string) => scope Self(scope SpanMemoryStream(.((.) string.Ptr, string.Length))).Parse();

	private Result<JsonTree> Parse() {
		Handle!(Advance());
		Handle!(Advance());

		tree = new .();

		defer {
			if (@return == .Err) {
				delete tree;
			}
		}

		switch (current) {
		case .LeftBracket:	tree.root = ParseArray().GetOrPropagate!();
		case .LeftBrace:	tree.root = ParseObject().GetOrPropagate!();
		default:			return .Err;
		}

		return tree;
	}

	private Result<Json> ParseElement() {
		mixin Return(Json json) {
			Handle!(Advance(), json);
			return json;
		}

		switch (current) {
		case .Null:					Return!(Json.Null());
		case .True:					Return!(Json.Bool(true));
		case .False:				Return!(Json.Bool(false));
		case .Number(let value):	Return!(Json.Number(value));
		case .String(let value):	Return!(tree.String(value));
		case .LeftBracket:			return Handle!(ParseArray());
		case .LeftBrace:			return Handle!(ParseObject());
		default:					return .Err;
		}
	}

	private Result<Json> ParseArray() {
		Handle!(Advance());
		Json json = tree.Array();

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
		Json json = tree.Object();

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

			BumpAllocator alloc = tree.[Friend]alloc;
			json.Put(new:alloc String(name), element, false);

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

	private mixin Handle<T>(Result<T> result, Json? toDelete = null) {
		if (result == .Err) {
			if (toDelete.HasValue) toDelete.Value.Dispose();
			return .Err;
		}

		result.Value
	}
}