using System;

namespace Meteorite {
	// data length = ((1 << edgeBits * 3) + valuesPerLong - 1) / valuesPerLong

	class PalettedContainer<T> {
		private T[] ids;
		private T defaultValue;
		private int32[] palette ~ delete _;
		private uint64[] data ~ delete _;
		private int bitsPerEntry, valuesPerLong, edgeBits;
		private uint64 individualValueMask;

		public this(T[] ids, T defaultValue, int32[] palette, uint64[] data, int bitsPerEntry, int edgeBits) {
			this.ids = ids;
			this.defaultValue = defaultValue;
			this.palette = palette;
			this.data = data;
			this.bitsPerEntry = bitsPerEntry;

			if (bitsPerEntry != 0) {
				this.valuesPerLong = 64 / bitsPerEntry;
				this.edgeBits = edgeBits;
				this.individualValueMask = (1 << bitsPerEntry) - 1;
			}
		}

		public T Get(int x, int y, int z) {
			uint64 entry = 0;

			if (bitsPerEntry != 0) {
				int index = (y << edgeBits | z) << edgeBits | x;
				let startLong = index / valuesPerLong;
				let startOffset = index % valuesPerLong * bitsPerEntry;
				entry = (data[startLong] >> startOffset) & individualValueMask;
			}

			T value = ids[palette[(.) entry]];
			return value != null ? value : defaultValue;
		}
	}
}