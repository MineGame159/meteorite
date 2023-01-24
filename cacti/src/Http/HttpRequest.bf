using System;
using System.Collections;

namespace Cacti.Http;

enum HttpMethod {
	Get,
	Post,
	Put,
	Delete
}

class HttpRequest {
	public HttpMethod method;
	
	private append String urlString = .(64);
	public HttpUrl url;

	public append Dictionary<String, String> headers = .(16);
	public String body ~ delete _;

	public this(HttpMethod method) {
		this.method = method;
	}

	public ~this() {
		for (let header in headers) {
			delete header.key;
			delete header.value;
		}
	}

	public Result<Self> Url(StringView url) {
		this.urlString.Set(url);
		this.url = HttpUrl.Parse(urlString).GetOrPropagate!();

		return this;
	}

	public Self Header(StringView name, StringView value, bool replace = true) {
		String outKey;
		String outValue;

		if (headers.TryGetAlt(name, out outKey, out outValue)) {
			if (replace) {
				delete outKey;
				delete outValue;
			}
			else {
				return this;
			}
		}

		headers[new .(name)] = new .(value);
		return this;
	}

	public Self Body(StringView body) {
		if (this.body == null) this.body = new .();

		this.body.Set(body);
		return this;
	}

	public Self Body(Json json) {
		if (this.body == null) this.body = new .();

		this.body.Clear();
		JsonWriter.Write(json, this.body);

		return this;
	}
}