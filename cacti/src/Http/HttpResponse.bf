using System;
using System.Collections;

namespace Cacti.Http;

class HttpResponse {
	private String string ~ delete _;

	public HttpStatus status;
	public Dictionary<StringView, StringView> headers = new .() ~ delete _;
	public StringView body;

	public StringView GetHeader(StringView name) => headers.GetValueOrDefault(name);

	public Result<Json> GetJson() => JsonParser.ParseString(body);

	public Result<void> Parse(String string) {
		this.string = string;

		for (let line in Utils.Lines(string)) {
			// Status
			if (@line.Index == 0) {
				int spaceI = line.IndexOf(' ');
				if (spaceI == -1) return .Err;

				StringView statusString = line[(spaceI + 1)...];

				if (!statusString[statusString.Length - 1].IsDigit) {
					spaceI = statusString.IndexOf(' ');
					if (spaceI == -1) return .Err;

					statusString = statusString[...(spaceI - 1)];
				}

				switch (int.Parse(statusString)) {
				case .Ok(let val):	status = HttpStatus.FromCode(val).GetOrPropagate!();
				case .Err:			return .Err;
				}

				continue;
			}

			// Body
			if (line.IsEmpty) {
				body = string[@line.Position...]..Trim();
				break;
			}

			// Headers
			StringSplitEnumerator headerSplit = line.Split(':');

			StringView name = headerSplit.GetNext().GetOrPropagate!()..Trim();
			StringView value = headerSplit.GetNext().GetOrPropagate!()..Trim();

			headers[name] = value;
		}

		return .Ok;
	}
}