using System;
using System.IO;

namespace Cacti.Json;

enum JsonToken {
	case LeftBrace;
	case RightBrace;

	case LeftBracket;
	case RightBracket;

	case Colon;
	case Comma;

	case Null;
	case True;
	case False;

	case Number(double value);
	case String(StringView value);

	case EOF;
}

class JsonLexer {
	private Stream stream;

	private bool first = true;
	private char8 current, next;
	
	private append String buffer = .(32);

	public this(Stream stream) {
		this.stream = stream;
	}

	private mixin Token(JsonToken token) {
		Handle!(Advance());
		return token;
	}

	public Result<JsonToken> GetNext() {
		if (first) {
			Handle!(Advance());
			Handle!(Advance());

			first = false;
		}

		Handle!(SkipWhitespace());

		if (IsAtEnd) {
			return JsonToken.EOF;
		}

		switch (current) {
		case '{':	Token!(JsonToken.LeftBrace);
		case '}':	Token!(JsonToken.RightBrace);

		case '[':	Token!(JsonToken.LeftBracket);
		case ']':	Token!(JsonToken.RightBracket);

		case ':':	Token!(JsonToken.Colon);
		case ',':	Token!(JsonToken.Comma);

		case 'n':	return Identifier(.Null, "ull");
		case 't':	return Identifier(.True, "rue");
		case 'f':	return Identifier(.False, "alse");

		case '"':	return String();

		default:
			if (current == '-' || current.IsDigit) return Number();

			return .Err;
		}
	}

	private Result<JsonToken> Number() {
		mixin Digits() {
			while (current.IsDigit) {
				buffer.Append(current);
				Handle!(Advance());
			}
		}

		buffer.Clear();

		if (current == '-') {
			buffer.Append(current);
			Handle!(Advance());
		}

		Digits!();

		if (current == '.') {
			buffer.Append(current);
			Handle!(Advance());

			Digits!();
		}

		switch (double.Parse(buffer)) {
		case .Ok(let val):	return JsonToken.Number(val);
		case .Err:			return .Err;
		}
	}

	private Result<JsonToken> String() {
		mixin Character() {
			if (IsAtEnd) return .Err;
			if (current == '\n') return .Err;

			if (current == '\\') {
				if (next == 'n') {
					buffer.Append('\n');
					Handle!(Advance());
				}
				else if (next == '"') {
					buffer.Append('"');
					Handle!(Advance());
				}
				else if (next == '\\') {
					buffer.Append('\\');
					Handle!(Advance());
				}
				else buffer.Append(current);

				Handle!(Advance());
			}
			else {
				buffer.Append(current);
				Handle!(Advance());
			}
		}

		buffer.Clear();
		Handle!(Advance());

		while (current != '"') {
			Character!();
		}

		Handle!(Advance());

		return JsonToken.String(buffer);
	}

	private Result<JsonToken> Identifier(JsonToken token, StringView rest) {
		Handle!(Advance());

		for (char8 char in rest) {
			if (char != current) return .Err;
			Handle!(Advance());
		}

		return token;
	}

	private Result<void> SkipWhitespace() {
		while (current.IsWhiteSpace) {
			Handle!(Advance());
		}

		return .Ok;
	}

	private bool IsAtEnd => current == '\0';
	
	private Result<void> Advance() {
		current = next;

		char8 char = ?;

		switch (stream.TryRead(.((uint8*) &char, 1))) {
		case .Ok(let val):
			next = val == 1 ? char : '\0';
			return .Ok;
		case .Err:
			return .Err;
		}
	}

	private mixin Handle(Result<void> result) {
		if (result == .Err) {
			return .Err;
		}
	}
}