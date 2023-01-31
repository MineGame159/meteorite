using System;
using System.Collections;

namespace Cacti.Http;

interface HttpStream {
	Result<void> Write(Span<uint8> data);

	Result<int> Read(Span<uint8> data);
}

class MemoryHttpStream : HttpStream {
	private List<uint8> bytes ~ delete _;
	private int position;

	public this(List<uint8> data, int position) {
		this.bytes = data;
		this.position = position;
	}

	public Result<void> Write(Span<uint8> data) {
		bytes.EnsureCapacity(bytes.Count + data.Length, true);

		Internal.MemCpy(bytes.Ptr + bytes.Count, data.Ptr, data.Length);
		bytes.[Friend]mSize += (.) data.Length;

		return .Ok;
	}

	public Result<int> Read(Span<uint8> data) {
		int toRead = Math.Min(bytes.Count - position, data.Length);
		if (toRead == 0) return 0;

		Internal.MemCpy(data.Ptr, bytes.Ptr + position, toRead);
		position += toRead;

		return toRead;
	}
}

class StringHttpStream : HttpStream {
	private String string;
	private bool owns;

	private int position;

	public this(String string, bool owns) {
		this.string = string;
		this.owns = owns;
	}

	public ~this() {
		if (owns) {
			delete string;
		}
	}

	public Result<void> Write(Span<uint8> data) {
		string.Append((char8*) data.Ptr, data.Length);
		return .Ok;
	}

	public Result<int> Read(Span<uint8> data) {
		int toRead = Math.Min(string.Length - position, data.Length);
		if (toRead == 0) return 0;

		Internal.MemCpy(data.Ptr, &string[position], toRead);
		position += toRead;
		
		return toRead;
	}
}

class CombinedHttpStream : HttpStream {
	private HttpStream first ~ delete _;
	private HttpStream second ~ delete _;

	private bool readingSecond;

	public this(HttpStream first, HttpStream second) {
		this.first = first;
		this.second = second;
	}

	public Result<void> Write(Span<uint8> data) {
		return .Err;
	}

	public Result<int> Read(Span<uint8> data) {
		// Read second
		if (readingSecond) {
			return second.Read(data);
		}

		// Read first and switch to second if first runs out of data
		int read = first.Read(data);

		if (read == 0) {
			readingSecond = true;
			return Read(data);
		}

		return read;
	}
}