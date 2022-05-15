using System;
using System.IO;

namespace Meteorite {
	class SpanMemoryStream : Stream {
		Span<uint8> mMemory;
		int mPosition = 0;

		public override int64 Position
		{
			get
			{
				return mPosition;
			}

			set
			{
				mPosition = (.)value;
			}
		}

		public override int64 Length
		{
			get
			{
				return mMemory.Length;
			}
		}

		public override bool CanRead
		{
			get
			{
				return true;
			}
		}

		public override bool CanWrite
		{
			get
			{
				return true;
			}
		}

		public this()
		{
			mMemory = .();
		}

		public this(Span<uint8> memory)
		{
			mMemory = memory;
		}

		public override Result<int> TryRead(Span<uint8> data)
		{
			let count = data.Length;
			if (count == 0)
				return .Ok(0);
			int readBytes = Math.Min(count, mMemory.Length - mPosition);
			if (readBytes <= 0)
				return .Ok(readBytes);

			Internal.MemCpy(data.Ptr, &mMemory[mPosition], readBytes);
			mPosition += readBytes;
			return .Ok(readBytes);
		}

		public override Result<int> TryWrite(Span<uint8> data)
		{
			return .Err;
		}

		public override Result<void> Close()
		{
			return .Ok;
		}
	}
}