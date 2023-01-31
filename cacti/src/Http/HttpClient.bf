using System;
using System.Net;
using System.Collections;
using System.Diagnostics;

using Cacti.Crypto;

namespace Cacti.Http;

class HttpClient {
	private const int BUFFER_SIZE = 512;

	private Crypto crypto ~ delete _;
	private uint8[] payload ~ delete _;

	public this() {
		Socket.Init();
	}

	public Result<HttpResponse> Send(HttpRequest request) {
		// Setup headers
		request.SetHeader(.Host, request.Url.hostname);
		request.SetHeader(.Connection, "close");
		request.SetHeader(.UserAgent, "Cacti", false);

		// Get payload
		int size = request.GetPayloadSize();

		if (payload == null || payload.Count < size) {
			delete payload;
			payload = new .[size];
		}

		request.GetPayload(payload);

		// Execute
		return Execute(request.Url, .(payload, 0, size), request.Body);
	}
	
	private Result<HttpResponse> Execute(HttpUrl url, Span<uint8> payload, HttpStream body) {
		// Connect to the server
		Socket socket = new .();

		socket.Blocking = true;
		socket.Connect(url.hostname, url.https ? 443 : 80).GetOrPropagate!();

		// Create either HTTP or HTTPs connection
		HttpStream stream;
		
		if (url.https) stream = new HttpsConnection(socket, GetSSL(socket, url));
		else stream = new HttpConnection(socket);

		// Send payload
		stream.Write(payload).GetOrPropagate!();

		// Send body
		if (body != null) {
			uint8[BUFFER_SIZE] bytes = ?;

			while (true) {
				int read = body.Read(bytes).GetOrPropagate!();
				if (read == 0) break;

				stream.Write(.(&bytes, read));
			}
		}

		// Read response
		List<uint8> data = new .();
		uint8[BUFFER_SIZE] bytes = ?;

		int headerLength = 0;

		while (headerLength == 0) {
			int read = stream.Read(bytes).GetOrPropagate!();

			data.EnsureCapacity(data.Count + read, true);
			Internal.MemCpy(data.Ptr + data.Count, &bytes, read);
			data.[Friend]mSize += (.) read;

			if (data.Count > 3) {
				for (int i = 3; i < data.Count; i++) {
					if (data[i - 3] == '\r' && data[i - 2] == '\n' && data[i - 1] == '\r' && data[i] == '\n') {
						headerLength = i + 1;
						break;
					}
				}
			}
		}

		if (headerLength == 0) {
			return .Err;
		}

		// Parse response
		String responseString = new .((char8*) data.Ptr, headerLength);
		HttpResponse response = new .(.OK);

		if (response.Parse(.Owned(responseString)) == .Err) {
			delete response;
			return .Err;
		}

		// Since there is a hacky List<uint8> buffer to parse the HTTP message before the body there is a possibility that the buffer contains leftover body data
		// To fix that wrap the stream in a combined stream that first reads the leftover buffer and then the HTTP stream
		if (data.Count > headerLength) {
			stream = new CombinedHttpStream(
				new MemoryHttpStream(data, headerLength),
				stream
			);
		}
		else {
			delete data;
		}

		// Apply Transfer-Encoding header to the stream
		StringView transferEncoding = response.GetHeader(.TransferEncoding);

		if (transferEncoding.IsEmpty) response.SetBody(stream);
		else if (transferEncoding == "chunked") response.SetBody(new ChunkedHttpStream(stream, BUFFER_SIZE));
		else {
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