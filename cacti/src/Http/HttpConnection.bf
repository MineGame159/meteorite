using System;
using System.Net;
using System.Collections;
using System.Diagnostics;

namespace Cacti.Http;

interface IHttpConnection {
	Result<void> Send(Span<uint8> data);

	// TODO: Switch to a custom buffer
	Result<void> Read(List<uint8> data);
}

class HttpConnection : IHttpConnection {
	private const int READ_SIZE = 1024;

	private Socket socket;

	public this(Socket socket) {
		this.socket = socket;
	}

	public Result<void> Send(Span<uint8> data) {
		var data;

		while (data.Length > 0) {
			int sent = socket.Send(data.Ptr, data.Length).GetOrPropagate!();
			data.RemoveFromStart(sent);
		}

		return .Ok;
	}

	public Result<void> Read(List<uint8> data) {
		while (true) {
			data.EnsureCapacity(data.Count + READ_SIZE, true);
			int read = socket.Recv(data.Ptr + data.Count, READ_SIZE).GetOrPropagate!();

			if (read == 0) break;
			data.[Friend]mSize += (.) read;

			// TODO: I don't know if this is correct but the default behavior of when it returns .Err is kinda weird
			if (read < READ_SIZE) break;
		}

		Debug.Assert(!data.IsEmpty);
		return .Ok;
	}
}

class HttpsConnection : IHttpConnection {
	private const int READ_SIZE = 1024;

	private WolfSSL.SSL* ssl ~ WolfSSL.Free(_);

	public this(WolfSSL.SSL* ssl) {
		this.ssl = ssl;
	}

	public Result<void> Send(Span<uint8> data) {
		int written = WolfSSL.Write(ssl, data.Ptr, (.) data.Length);
		if (written <= 0) return .Err;

		Debug.Assert(written == data.Length);
		return .Ok;
	}

	public Result<void> Read(List<uint8> data) {
		int read = 0;

		while (true) {
			data.EnsureCapacity(data.Count + READ_SIZE, true);
			int32 readThisCall = WolfSSL.Read(ssl, data.Ptr + data.Count, READ_SIZE);

			if (readThisCall < 0) return .Err;
			if (readThisCall == 0) break;

			data.[Friend]mSize += readThisCall;
			read += readThisCall;
		}

		Debug.Assert(read > 0);
		return .Ok;
	}
}