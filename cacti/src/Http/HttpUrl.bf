using System;

namespace Cacti.Http;

struct HttpUrl : this(StringView string, bool https, StringView hostname, StringView path) {
	public static Result<Self> Parse(StringView url) {
		StringView string = url;
		var url;

		// HTTPS
		bool https;

		if (url.StartsWith("http://")) {
			https = false;
			url = url[7...];
		}
		else if (url.StartsWith("https://")) {
			https = true;
			url = url[8...];
		}
		else {
			return .Err;
		}

		// Path
		StringView path = "";
		int slashI = url.IndexOf('/');

		if (slashI != -1) {
			path = url[slashI...];
			url = url[...(slashI - 1)];
		}

		// Return
		return HttpUrl(string, https, url, path);
 	}

	public override void ToString(String str) {
		str.AppendF("{}://{}{}", https ? "https" : "http", hostname, path);
	}
}