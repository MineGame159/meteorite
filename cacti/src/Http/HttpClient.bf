using System;
using System.Net;
using System.Collections;
using System.Diagnostics;

using Cacti.Crypto;

namespace Cacti.Http;

class HttpClient {
	private Crypto crypto ~ delete _;
	private uint8[] payload ~ delete _;

	public this() {
		Socket.Init();
	}

	public Result<HttpResponse> Send(HttpRequest request) {
		// Setup headers
		request.SetHeader("Host", request.Url.hostname);
		request.SetHeader("Connection", "close");
		request.SetHeader("User-Agent", "Cacti", false);

		// Get payload
		int size = request.GetPayloadSize();

		if (payload == null || payload.Count < size) {
			delete payload;
			payload = new .[size];
		}

		request.GetPayload(payload);

		// Execute
		return Execute(request.Url, .(payload, 0, size));
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
		String responseString = new .((char8*) data.Ptr, data.Count);
		HttpResponse response = new .(.OK);

		if (response.Parse(.Owned(responseString)) == .Err) {
			delete response;
			return .Err;
		}

		return response;
	}

	private SSL GetSSL(Socket socket, HttpUrl url) {
		if (crypto == null) {
			crypto = new .();
			crypto.SetVerify(.None, null);
		}

		SSL ssl = new .(crypto);

		ssl.UseSNI(0, .((uint8*) url.hostname.Ptr, url.hostname.Length));
		ssl.SetSocket(socket);

		return ssl;
	}
}