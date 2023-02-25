using System;

namespace Meteorite;

interface IBitStorage {
	public delegate void(int) Upgrade { get; set; };

	int32 Get(int i);

	bool Set(int i, int32 value);
}

class SingleBitStorage : IBitStorage {
	private int32 value;

	public delegate void(int) Upgrade { get; set; } ~ delete _;

	public this(int32 value) {
		this.value = value;
	}

	public int32 Get(int i) => value;

	public bool Set(int i, int32 value) {
		if (value > 0) {
			Upgrade(2);
			return true;
		}

		this.value = value;
		return false;
	}
}

class BitStorage : IBitStorage {
	private uint64[] data ~ delete _;

	private int bitsPerEntry, entriesPerLong, maxValue;
	private uint64 mask;

	public delegate void(int) Upgrade { get; set; } ~ delete _;

	public this(uint64[] data, int bitsPerEntry) {
		this.data = data;
		this.bitsPerEntry = bitsPerEntry;
		this.entriesPerLong = 64 / bitsPerEntry;
		this.maxValue = (1 << bitsPerEntry) - 1;
		this.mask = (1 << bitsPerEntry) - 1;
	}

	public this(int edgeBits, int bitsPerEntry) : this(new uint64[GetDataLength(edgeBits, bitsPerEntry)], bitsPerEntry) {}

	public int32 Get(int i) {
		let startLong = i / entriesPerLong;
		let startOffset = i % entriesPerLong * bitsPerEntry;
		return (.) ((data[startLong] >> startOffset) & mask);
	}

	public bool Set(int i, int32 value) {
		if (value >= maxValue) {
			Upgrade(bitsPerEntry + 1);
			return true;
		}

		let startLong = i / entriesPerLong;
		let startOffset = i % entriesPerLong * bitsPerEntry;
		data[startLong] = (data[startLong] & ~(mask << startOffset)) | ((uint64) value << startOffset);

		return false;
	}

	private static int GetDataLength(int edgeBits, int bitsPerEntry) {
		int entriesPerLong = 64 / bitsPerEntry;
		return ((1 << edgeBits * 3) + entriesPerLong - 1) / entriesPerLong;
	}
}