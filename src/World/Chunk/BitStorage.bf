using System;

namespace Meteorite {
	interface IBitStorage {
		int32 Get(int i);
	}

	class SingleBitStorage : IBitStorage {
		private int32 value;

		public this(int32 value) {
			this.value = value;
		}

		public int32 Get(int i) => value;
	}

	class BitStorage : IBitStorage {
		private uint64[] data ~ delete _;

		private int bitsPerEntry, entriesPerLong;
		private uint64 mask;

		public this(uint64[] data, int bitsPerEntry) {
			this.data = data;
			this.bitsPerEntry = bitsPerEntry;
			this.entriesPerLong = 64 / bitsPerEntry;
			this.mask = (1 << bitsPerEntry) - 1;
		}

		public int32 Get(int i) {
			let startLong = i / entriesPerLong;
			let startOffset = i % entriesPerLong * bitsPerEntry;
			return (.) ((data[startLong] >> startOffset) & mask);
		}
	}
}