using System;

using Cacti.Json;

namespace Cacti.Http;

class HttpResponse : HttpMessage {
	public HttpStatus Status;

	public this(HttpStatus status) {
		this.Status = status;
	}

	public Result<void> GetString(String string) {
		uint8[512] data = ?;

		while (true) {
			int read = body.Read(data).GetOrPropagate!();
			if (read == 0) break;

			string.Append((char8*) &data, read);
		}

		return .Ok;
	}

	public Result<Json> GetJson() {
		String string = new .(512);

		if (GetString(string) == .Err) {
			delete string;
			return .Err;
		}
		
		Result<Json> result = JsonParser.Parse(string);

		delete string; // defer does not seem to be working once again
		return result;
	}

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