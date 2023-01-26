using System;
using System.Net;
using System.Threading;
using System.Collections;
using System.Diagnostics;

namespace Cacti.Http;

typealias HttpHandler = delegate HttpResponse(HttpRequest request);

class HttpServer {
	private uint16 port;
	private Socket listener ~ delete _;
	private HttpHandler handler ~ delete _;

	private bool running;
	private Thread thread;
	private WaitEvent stopEvent ~ delete _;

	private int refCount = 1;
	private bool waitForStop = true;

	public this(uint16 port, HttpHandler handler) {
		Socket.Init();

		this.port = port;
		this.listener = new .();
		this.handler = handler;

		this.thread = new .(new => Run);
		this.stopEvent = new .();
	}

	public ~this() {
		Debug.Assert(refCount == 0);

		if (running) {
			Stop();
		}
	}

	public void AddRef() {
		Interlocked.Increment(ref refCount);
	}

	public bool Release() {
		Debug.Assert(refCount > 0);

		Interlocked.Decrement(ref refCount);
		if (refCount == 0) {
			delete this;
			return true;
		}

		return false;
	}

	public Result<void> Start() {
		listener.Blocking = true;
		listener.Listen(port).GetOrPropagate!();

		running = true;
		thread.Start();

		return .Ok;
	}

	public void Stop() {
		running = false;

		if (waitForStop) {
			stopEvent.WaitFor();
		}
	}

	private void Run() {
		// Create state
		List<uint8> data = new .(1024);
		uint8[] payload = null;

		bool deleted = false;

		// Listen for requests
		while (!deleted && running) {
			// Wait for incoming connections
			Socket.FDSet listenSet = .();
			listenSet.Add(listener.NativeSocket);

			int ready = Socket.Select(&listenSet, null, null, 1000);
			if (ready != 1) continue;

			// Accept
			Socket socket = scope .();

			socket.Blocking = true;
			if (socket.AcceptFrom(listener) == .Err) continue;

			// Read request
			HttpConnection connection = scope .(socket);

			data.Clear();
			if (connection.Read(data) == .Err) continue;

			// Handle request
			StringView requestString = .((.) data.Ptr, data.Count);

			HttpRequest request = scope .(.Get);
			if (request.Parse(.View(requestString)) == .Err) continue;

			AddRef();
			HttpResponse response = handler(request);

			defer {
				delete response;

				waitForStop = false;
				deleted = Release();

				if (!deleted) {
					waitForStop = true;
				}
			}

			// Send response
			response.SetHeader("Connection", "close");

			int size = response.GetPayloadSize();

			if (payload == null || payload.Count < size) {
				delete payload;
				payload = new .[size];
			}

			response.GetPayload(payload);

			connection.Send(.(payload, 0, size));
		}

		// Signal stop event
		if (!deleted) {
			stopEvent.Set();
		}

		// Delete state
		delete data;
		delete payload;
	}
}