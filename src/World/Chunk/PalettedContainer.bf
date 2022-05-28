using System;

namespace Meteorite {
	// data length = ((1 << edgeBits * 3) + valuesPerLong - 1) / valuesPerLong

	class PalettedContainer<T> {
		private IPalette<T> palette ~ delete _;
		private IBitStorage storage ~ delete _;

		private int edgeBits;

		public this(IPalette<T> palette, IBitStorage storage, int edgeBits) {
			this.palette = palette;
			this.storage = storage;
			this.edgeBits = edgeBits;
		}

		public T Get(int x, int y, int z) {
			int32 id = storage.Get((y << edgeBits | z) << edgeBits | x);
			return palette.GetValue(id);
		}
	}
}