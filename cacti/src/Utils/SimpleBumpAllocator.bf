using System;
using System.Collections;

namespace Cacti;

class SimpleBumpAllocator : IRawAllocator {
	private List<Pool> pools = new .() ~ DeleteContainerAndItems!(_);

	public void* Alloc(int size, int align) {
		for (Pool pool in pools) {
			void* ptr = pool.Alloc(size, align);
			if (ptr != null) return ptr;
		}

		Pool pool = new .(Math.Max(4096, size + align));
		pools.Add(pool);

		return pool.Alloc(size, align);
	}

	[SkipCall]
	public void Free(void* ptr) {}

	public void FreeAll() {
		for (Pool pool in pools) {
			pool.FreeAll();
		}
	}

	class Pool {
		private Span<uint8> buffer ~ delete buffer.Ptr;
		private int offset;

		public this(int size) {
			this.buffer = .(new uint8[size]* (?), size);
		}

		public void* Alloc(int size, int align) {
			uint8* ptr = (.) (void*) (int) Math.Align((int) (void*) (buffer.Ptr + offset), align);
			uint8* end = buffer.Ptr + buffer.Length;

			if (ptr > end) return null;

			offset += ((ptr + size) - (buffer.Ptr + offset));
			return ptr;
		}

		public void FreeAll() {
			offset = 0;
		}
	}
}