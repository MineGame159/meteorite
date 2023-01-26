using System;
using System.Collections;
using System.Diagnostics;

namespace Cacti.Http;

enum HttpMessageData : IEquatable<Self>, IEquatable<StringView>, IHashable, IDisposable {
	case Empty;
	case Owned(String string);
	case View(StringView string);

	public StringView String { get {
		switch (this) {
		case .Empty:				return "";
		case .Owned(let string):	return string;
		case .View(let string):		return string;
		}
	} }

	public bool Equals(HttpMessageData other) => String == other.String;
	public bool Equals(StringView other) => String == other;
	
	public int GetHashCode() {
		switch (this) {
		case .Empty:				return "".GetHashCode();
		case .Owned(let string):	return string.GetHashCode();
		case .View(let string):		return string.GetHashCode();
		}
	}

	public void Dispose() {
		if (this case .Owned(let string)) {
			delete string;
		}
	}

	public static operator StringView(Self data) => data.String;
}

typealias HttpHeader = (StringView name, StringView value);

abstract class HttpMessage {
	protected HttpMessageData data ~ _.Dispose();

	protected Dictionary<HttpMessageData, HttpMessageData> headers = new .() ~ delete _;
	protected HttpMessageData body ~ _.Dispose();

	public ~this() {
		for (let header in headers) {
			header.key.Dispose();
			header.value.Dispose();
		}
	}

	public Self SetHeader(StringView name, StringView value, bool replace = true) {
		HttpMessageData outKey;
		HttpMessageData outValue;

		if (headers.TryGetAlt(name, out outKey, out outValue)) {
			if (replace) {
				outKey.Dispose();
				outValue.Dispose();
			}
			else {
				return this;
			}
		}

		headers[.Owned(new .(name))] = .Owned(new .(value));
		return this;
	}

	public StringView GetHeader(StringView name) {
		HttpMessageData value;
		if (headers.TryGetValueAlt(name, out value)) return value.String;

		return "";
	}

	public HttpHeaderEnumerator Headers => .(this);

	public Self SetBody(StringView body) {
		this.body.Dispose();
		this.body = .Owned(new .(body));

		if (!Body.IsEmpty) {
			SetHeader("Content-Type", "text/plain");
			SetHeader("Content-Length", Body.Length.ToString(.. scope .()));
		}

		return this;
	}

	public Self SetBodyJson(StringView body) {
		this.body.Dispose();
		this.body = .Owned(new .(body));

		if (!Body.IsEmpty) {
			SetHeader("Content-Type", "application/json");
			SetHeader("Content-Length", Body.Length.ToString(.. scope .()));
		}

		return this;
	}

	public Self SetBody(Json json) {
		this.body.Dispose();
		this.body = .Owned(JsonWriter.Write(json, .. new .()));

		if (!Body.IsEmpty) {
			SetHeader("Content-Type", "application/json");
			SetHeader("Content-Length", Body.Length.ToString(.. scope .()));
		}

		return this;
	}

	public Self SetBody(Dictionary<StringView, StringView> data) {
		this.body.Dispose();

		String str = new .();
		int i = 0;

		for (let pair in data) {
			if (i++ > 0) str.Append('&');

			str.Append(pair.key);
			str.Append('=');
			str.Append(pair.value);
		}

		this.body = .Owned(str);

		if (!Body.IsEmpty) {
			SetHeader("Content-Type", "application/x-www-form-urlencoded");
			SetHeader("Content-Length", Body.Length.ToString(.. scope .()));
		}

		return this;
	}

	public StringView Body => body;

	protected abstract Result<void> ParseStatus(StringView string);

	protected abstract int GetPayloadStatusSize();

	protected abstract void GetPayloadStatus(String string);

	public Result<void> Parse(HttpMessageData data) {
		this.data = data;
		
		// Parse
		for (let line in Utils.Lines(data)) {
			// Status
			if (@line.Index == 0) {
				ParseStatus(line).GetOrPropagate!();
				continue;
			}

			// Body
			if (line.IsEmpty) {
				body = .View(data.String[@line.Position...]..Trim());
				break;
			}

			// Headers
			StringSplitEnumerator headerSplit = line.Split(':');

			StringView name = headerSplit.GetNext().GetOrPropagate!()..Trim();
			StringView value = headerSplit.GetNext().GetOrPropagate!()..Trim();
			
			headers[.View(name)] = .View(value);
		}

		return .Ok;
	}

	public int GetPayloadSize() {
		int size = 0;

		// Status
		size += GetPayloadStatusSize() + 2;

		// Headers
		for (let header in Headers) {
			size += header.name.Length + 2 + header.value.Length + 2;
		}

		// Empty line
		size += 2;

		// Body
		size += Body.Length;

		return size;
	}

	public void GetPayload(uint8[] payload) {
		// Utility functions
		int offset = 0;

		void Append(StringView str) {
			if (str.IsEmpty) return;
			Debug.Assert(offset + str.Length <= payload.Count);

			Internal.MemCpy(&payload[offset], str.Ptr, str.Length);
			offset += str.Length;
		}

		void AppendF(StringView str, params Object[] args) {
			if (str.IsEmpty) return;
			Append(scope String()..AppendF(str, params args));
		}

		// Status
		Append(GetPayloadStatus(.. scope .()));
		Append("\r\n");

		// Headers
		for (let header in Headers) {
			AppendF("{}: {}\r\n", header.name, header.value);
		}

		// Empty line
		Append("\r\n");

		// Body
		Append(Body);
	}

	public struct HttpHeaderEnumerator : IEnumerator<HttpHeader> {
		private Dictionary<HttpMessageData, HttpMessageData>.Enumerator enumerator;

		public this(HttpMessage message) {
			this.enumerator = message.headers.GetEnumerator();
		}

		public Result<HttpHeader> GetNext() mut {
			switch (enumerator.GetNext()) {
			case .Ok(let val):	return (val.key.String, val.value.String);
			case .Err:			return .Err;
			}
		}
	}
}