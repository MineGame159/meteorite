using System;

namespace Cacti.Http;

enum HttpMethod {
	case Get,
		 Post,
		 Put,
		 Delete;

	public StringView Name { get {
		switch (this) {
		case .Get:		return "GET";
		case .Post:		return "POST";
		case .Put:		return "PUT";
		case .Delete:	return "DELETE";
		}
	} }

	public override void ToString(String str) {
		str.Append(Name);
	}
}

class HttpRequest : HttpMessage {
	private String urlString ~ delete _;

	public HttpMethod Method { get; private set; }
	public HttpUrl Url { get; private set; };

	public this(HttpMethod method) {
		this.Method = method;
	}

	public Result<Self> SetUrl(StringView url) {
		if (this.urlString == null) this.urlString = new .(url.Length);

		this.urlString.Set(url);
		this.Url = HttpUrl.Parse(urlString).GetOrPropagate!();
		
		return this;
	}

	protected override Result<void> ParseStatus(StringView string) {
		var string;

		// Method
		int spaceI = string.IndexOf(' ');
		if (spaceI == -1) return .Err;

		switch (Enum.Parse<HttpMethod>(string[...(spaceI - 1)], true)) {
		case .Ok(let val):	Method = val;
		case .Err:			return .Err;
		}

		string = string[(spaceI + 1)...];

		// Path
		spaceI = string.IndexOf(' ');
		if (spaceI == -1) return .Err;

		Url = .(false, "", string[...(spaceI - 1)]);

		return .Ok;
	}
	
	protected override int GetPayloadStatusSize() => Method.Name.Length + 1 + Url.path.Length + 9;

	protected override void GetPayloadStatus(String string) => string.AppendF("{} {} HTTP/1.1", Method, Url.path);
}