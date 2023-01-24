using System;
using System.Net;
using System.Collections;
using System.Diagnostics;

namespace Cacti.Http;

class HttpClient {
	private WolfSSL.Ctx* sslCtx;
	private uint8[] payload ~ delete _;

	public this() {
		Socket.Init();
	}

	public ~this() {
		if (sslCtx != null) {
			WolfSSL.CtxFree(sslCtx);
		}
	}

	public Result<HttpResponse> Send(HttpRequest request) {
		// Setup headers
		request.Header("Host", request.url.hostname);
		request.Header("Connection", "close");
		request.Header("User-Agent", "Cacti", false);

		// Get payload
		int size = GetRequestPayloadSize(request);

		if (payload == null || payload.Count < size) {
			delete payload;
			payload = new .[size];
		}

		GetRequestPayload(request, payload);

		// Execute
		return Execute(request.url, .(payload, 0, size));
	}
	
	private Result<HttpResponse> Execute(HttpUrl url, Span<uint8> payload) {
		// Connect to the server
		Socket socket = scope .();

		socket.Blocking = true;
		socket.Connect(url.hostname, url.https ? 443 : 80).GetOrPropagate!();

		// Create either HTTP or HTTPs connection
		IHttpConnection connection;
		
		if (url.https) connection = scope:: HttpsConnection(GetSSL(socket, url));
		else connection = scope:: HttpConnection(socket);

		// Send payload
		connection.Send(payload).GetOrPropagate!();

		// Read response
		List<uint8> data = scope .();
		connection.Read(data).GetOrPropagate!();

		// Parse response
		HttpResponse response = new .();

		if (response.Parse(new .((char8*) data.Ptr, data.Count)) == .Err) {
			delete response;
			return .Err;
		}

		return response;
	}

	private WolfSSL.SSL* GetSSL(Socket socket, HttpUrl url) {
		if (sslCtx == null) {
			int result = WolfSSL.Init();
			Runtime.Assert(result == 1);

			sslCtx = WolfSSL.CtxNew(WolfSSL.ClientMethod());
			Runtime.Assert(sslCtx != null);

			WolfSSL.CtxSetVerify(sslCtx, .None, null);
		}

		WolfSSL.SSL* ssl = WolfSSL.New(sslCtx);
		Runtime.Assert(ssl != null);

		int result = WolfSSL.UseSNI(ssl, 0, url.hostname.Ptr, (.) url.hostname.Length);
		Runtime.Assert(result == 1);

		result = WolfSSL.SetFd(ssl, (.) socket.NativeSocket);
		Runtime.Assert(result == 1);

		return ssl;
	}

	private static int32 VerifyAll(int32 preverfiy, void* store) => 1;

	private static int GetRequestPayloadSize(HttpRequest request) {
		int size = 0;

		// Status
		size += 4 + request.url.path.Length + 9 + 2;

		// Headers
		for (let header in request.headers) {
			size += header.key.Length + 2 + header.value.Length + 2;
		}

		// Empty line
		size += 2;

		// Body
		if (request.body != null) {
			size += request.body.Length;
		}

		return size;
	}

	private static void GetRequestPayload(HttpRequest request, uint8[] payload) {
		// Utility functions
		int offset = 0;

		void Append(StringView str) {
			Debug.Assert(offset + str.Length <= payload.Count);

			Internal.MemCpy(&payload[offset], str.Ptr, str.Length);
			offset += str.Length;
		}

		void AppendF(StringView str, params Object[] args) {
			Append(scope String()..AppendF(str, params args));
		}

		// Status
		AppendF("GET {} HTTP/1.1\r\n", request.url.path);

		// Headers
		for (let header in request.headers) {
			AppendF("{}: {}\r\n", header.key, header.value);
		}

		// Empty line
		Append("\r\n");

		// Body
		if (request.body != null) {
			Append(request.body);
		}
	}
}