using System;
using System.Net;
using System.Collections;
using System.Diagnostics;

using Cacti.Crypto;

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

	private SSL ssl ~ delete _;

	public this(SSL ssl) {
		this.ssl = ssl;
	}

	public Result<void> Send(Span<uint8> data) {
		int written = ssl.Write(data).GetOrPropagate!();

		Debug.Assert(written == data.Length);
		return .Ok;
	}

	public Result<void> Read(List<uint8> data) {
		int read = 0;

		while (true) {
			data.EnsureCapacity(data.Count + READ_SIZE, true);
			int32 readThisCall = (.) ssl.Read(.(data.Ptr + data.Count, READ_SIZE)).GetOrPropagate!();

			if (readThisCall < 0) return .Err;
			if (readThisCall == 0) break;

			data.[Friend]mSize += readThisCall;
			read += readThisCall;
		}

		Debug.Assert(read > 0);
		return .Ok;
	}
}