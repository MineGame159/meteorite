using System;
using System.Net;
using System.Collections;
using System.Diagnostics;

using Cacti.Crypto;

namespace Cacti.Http;

class HttpConnection : HttpStream {
	private const int READ_SIZE = 1024;

	private Socket socket ~ delete _;

	public this(Socket socket) {
		this.socket = socket;
	}

	public Result<void> Write(Span<uint8> data) {
		var data;

		while (data.Length > 0) {
			int sent = socket.Send(data.Ptr, data.Length).GetOrPropagate!();
			data.RemoveFromStart(sent);
		}

		return .Ok;
	}

	public Result<int> Read(Span<uint8> data) {
		// Not using Socket.Recv() since it returns an error when both an error happens or when it reaches the end of the stream
		int result = Socket.[Friend]recv(socket.NativeSocket, data.Ptr, (.) data.Length, 0);
		
		if (result == 0) {
			socket.[Friend]mIsConnected = false;
		}

		if (result <= -1) {
			socket.[Friend]CheckDisconnected();
			return .Err;
		}

		return result;
	}
}

class HttpsConnection : HttpStream {
	private const int READ_SIZE = 1024;

	private Socket socket ~ delete _;
	private SSL ssl ~ delete _;

	public this(Socket socket, SSL ssl) {
		this.socket = socket;
		this.ssl = ssl;
	}

	public Result<void> Write(Span<uint8> data) {
		int written = ssl.Write(data).GetOrPropagate!();

		Debug.Assert(written == data.Length);
		return .Ok;
	}

	public Result<int> Read(Span<uint8> data) {
		return ssl.Read(data);
	}
}