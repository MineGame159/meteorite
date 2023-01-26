using System;

namespace Cacti.Http;

class HttpResponse : HttpMessage {
	public HttpStatus Status;

	public this(HttpStatus status) {
		this.Status = status;
	}

	public Result<Json> GetJson() => JsonParser.ParseString(body);

	protected override Result<void> ParseStatus(StringView string) {
		int spaceI = string.IndexOf(' ');
		if (spaceI == -1) return .Err;

		StringView statusString = string[(spaceI + 1)...];

		if (!statusString[statusString.Length - 1].IsDigit) {
			spaceI = statusString.IndexOf(' ');
			if (spaceI == -1) return .Err;

			statusString = statusString[...(spaceI - 1)];
		}

		switch (int.Parse(statusString)) {
		case .Ok(let val):	Status = HttpStatus.FromCode(val).GetOrPropagate!();
		case .Err:			return .Err;
		}

		return .Ok;
	}

	protected override int GetPayloadStatusSize() => 9 + 4 + Status.Name.Length;

	protected override void GetPayloadStatus(String string) => string.AppendF("HTTP/1.1 {} {}", Status.Underlying, Status.Name);
}