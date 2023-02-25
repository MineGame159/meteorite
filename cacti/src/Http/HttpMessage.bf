using System;
using System.Collections;
using System.Diagnostics;

using Cacti.Json;

namespace Cacti.Http;

typealias HttpHeader = (HttpHeaderName name, StringView value);

abstract class HttpMessage {
	protected OwnableString data ~ _.Dispose();

	protected Dictionary<HttpHeaderName, OwnableString> headers = new .() ~ delete _;
	protected HttpStream body ~ delete _;

	public ~this() {
		for (let header in headers) {
			header.value.Dispose();
		}
	}

	public Self SetHeader(HttpHeaderName name, StringView value, bool replace = true) {
		HttpHeaderName outKey;
		OwnableString outValue;

		if (headers.TryGetAlt(name, out outKey, out outValue)) {
			if (replace) outValue.Dispose();
			else return this;
		}

		headers[name] = .Owned(new .(value));
		return this;
	}

	public StringView GetHeader(HttpHeaderName name) {
		OwnableString value;
		if (headers.TryGetValueAlt(name, out value)) return value.String;

		return "";
	}

	public HttpHeaderEnumerator Headers => .(this);

	public Self SetBody(HttpStream stream) {
		delete this.body;
		this.body = stream;

		return this;
	}

	public Self SetBody(StringView body) {
		SetHeader(.ContentType, "text/plain");
		SetHeader(.ContentLength, body.Length.ToString(.. scope .()));

		return SetBody(new StringHttpStream(new .(body), true));
	}

	public Self SetBodyJson(StringView body) {
		SetHeader(.ContentType, "application/json");
		SetHeader(.ContentLength, body.Length.ToString(.. scope .()));

		return SetBody(new StringHttpStream(new .(body), true));
	}

	public Self SetBody(Json json) {
		String string = JsonWriter.Write(json, .. new .(), false);

		SetHeader(.ContentType, "application/json");
		SetHeader(.ContentLength, string.Length.ToString(.. scope .()));
		
		return SetBody(new StringHttpStream(string, true));
	}

	public Self SetBody(Dictionary<StringView, StringView> data) {
		String string = new .();
		int i = 0;

		for (let pair in data) {
			if (i++ > 0) string.Append('&');

			string.Append(pair.key);
			string.Append('=');
			string.Append(pair.value);
		}

		SetHeader(.ContentType, "application/x-www-form-urlencoded");
		SetHeader(.ContentLength, string.Length.ToString(.. scope .()));

		return SetBody(new StringHttpStream(string, true));
	}

	public HttpStream Body => body;

	protected abstract Result<void> ParseStatus(StringView string);

	protected abstract int GetPayloadStatusSize();

	protected abstract void GetPayloadStatus(String string);

	public Result<void> Parse(OwnableString data) {
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
				break;
			}

			// Headers
			StringSplitEnumerator headerSplit = line.Split(':');

			HttpHeaderName name;

			switch (HttpHeaderName.Parse(headerSplit.GetNext().GetOrPropagate!()..Trim())) {
			case .Ok(let val):	name = val;
			case .Err:			continue;
			}

			StringView value = headerSplit.GetNext().GetOrPropagate!()..Trim();
			
			headers[name] = value;
		}

		return .Ok;
	}

	public int GetPayloadSize() {
		int size = 0;

		// Status
		size += GetPayloadStatusSize() + 2;

		// Headers
		for (let header in Headers) {
			size += header.name.Name.Length + 2 + header.value.Length + 2;
		}

		// Empty line
		size += 2;

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
			AppendF("{}: {}\r\n", header.name.Name, header.value);
		}

		// Empty line
		Append("\r\n");
	}

	public struct HttpHeaderEnumerator : IEnumerator<HttpHeader> {
		private Dictionary<HttpHeaderName, OwnableString>.Enumerator enumerator;

		public this(HttpMessage message) {
			this.enumerator = message.headers.GetEnumerator();
		}

		public Result<HttpHeader> GetNext() mut {
			switch (enumerator.GetNext()) {
			case .Ok(let val):	return (val.key, val.value.String);
			case .Err:			return .Err;
			}
		}
	}
}