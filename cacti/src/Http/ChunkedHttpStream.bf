using System;
using System.Diagnostics;

namespace Cacti.Http;

class ChunkedHttpStream : HttpStream {
	private HttpStream parent ~ delete _;

	private int chunkLength = -1;
	private int returnedLength;

	private uint8[] buffer ~ delete _;
	private int bufferSize;
	
	public this(HttpStream parent, int bufferSize) {
		this.parent = parent;
		this.buffer = new .[bufferSize];
	}

	public Result<void> Write(Span<uint8> data) {
		return .Err;
	}

	public Result<int> Read(Span<uint8> data) {
		// Get chunk length
		if (chunkLength == -1) {
			// Reset returned length
			returnedLength = 0;

			// Read into buffer
			ReadIntoBuffer().GetOrPropagate!();
			if (bufferSize == 0) return .Err;

			// Parse chunk header
			StringView header = TryGetChunkHeader();
			if (header.IsEmpty) return .Err; // TODO: Should probably retry at least one more time to make sure there is not any more data

			ParseChunkHeader(header).GetOrPropagate!();
		}

		// Return 0 if this is the last chunk
		if (chunkLength == 0) {
			return 0;
		}

		// Read chunk
		//     Return what is already buffered
		if (bufferSize > 0) {
			return CopyBufferToDest(data);
		}

		//     Read new data from parent
		ReadIntoBuffer().GetOrPropagate!();
		if (bufferSize == 0) return .Err;

		return CopyBufferToDest(data);
	}

	private int CopyBufferToDest(Span<uint8> dest) {
		// Make sure the amount we are trying to copy does not exceed the destination capacity
		int toCopy = Math.Min(bufferSize, dest.Length);

		// Check if we have enough data to return the entire remaining chunk
		if (returnedLength + toCopy >= chunkLength) {
			toCopy = chunkLength - returnedLength;
			chunkLength = -1;
		}

		// Copy data to destination
		Internal.MemCpy(dest.Ptr, buffer.Ptr, toCopy);
		returnedLength += toCopy;

		// Remove data from buffer
		RemoveFromBufferStart(toCopy);

		return toCopy;
	}

	private Result<void> ParseChunkHeader(StringView header) {
		// Parse
		StringSplitEnumerator split = header.Split(';', .RemoveEmptyEntries);

		chunkLength = int32.Parse(split.GetNext().GetOrPropagate!(), .HexNumber).GetOrPropagate!();

		// Move buffer to not include the header
		RemoveFromBufferStart(header.Length + 2);

		return .Ok;
	}

	private StringView TryGetChunkHeader() {
		if (bufferSize < 2) return "";

		char8 prevChar = (.) buffer[0];

		for (int i = 1; i < bufferSize; i++) {
			char8 char = (.) buffer[i];

			if (prevChar == '\r' && char == '\n') {
				return .((char8*) buffer.Ptr, i - 1);
			}

			prevChar = char;
		}

		return "";
	}

	private void RemoveFromBufferStart(int size) {
		Debug.Assert(bufferSize >= size);

		if (size != bufferSize) {
			Internal.MemCpy(buffer.Ptr, &buffer[size], bufferSize - size);
		}

		bufferSize -= size;
	}

	private Result<void> ReadIntoBuffer() {
		int read = parent.Read(.(buffer, 0, buffer.Count - bufferSize)).GetOrPropagate!();

		bufferSize += read;
		return .Ok;
	}
}