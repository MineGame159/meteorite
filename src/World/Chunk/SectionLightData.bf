using System;

namespace Meteorite;

enum LightType {
	Sky,
	Block
}

class SectionLightData {
	private NibbleArray skyNibbles ~ delete _;
	private NibbleArray blockNibbles ~ delete _;

	public this(uint8* skyNibbleData, uint8* blockNibbleData) {
		if (skyNibbleData != null) {
			skyNibbles = new .();
			skyNibbles.Set(skyNibbleData);
		}

		if (blockNibbleData != null) {
			blockNibbles = new .();
			blockNibbles.Set(blockNibbleData);
		}
	}

	public int Get(LightType type, int x, int y, int z) {
		if (type == .Sky) {
			return skyNibbles != null ? skyNibbles.Get(x, y, z) : 0;
		}

		return blockNibbles != null ? blockNibbles.Get(x, y, z) : 0;
	}

	public void Set(LightType type, int x, int y, int z, int value) {
		if (type == .Sky) {
			if (skyNibbles == null) skyNibbles = new .();
			skyNibbles.Set(x, y, z, value);
		}
		else {
			if (blockNibbles == null) blockNibbles = new .();
			blockNibbles.Set(x, y, z, value);
		}
	}

	public void Set(LightType type, uint8* nibbles) {
		if (type == .Sky) skyNibbles?.Set(nibbles);
		else blockNibbles?.Set(nibbles);
	}

	public void Clear(LightType type) {
		if (type == .Sky) skyNibbles?.Clear();
		else blockNibbles?.Clear();
	}
}

class NibbleArray {
	private uint8[2048] nibbles;

	public int Get(int x, int y, int z) {
		int index = Index!(x, y, z);

		int arrayIndex = ArrayIndex!(index);
		int smallerBits = OccupiesSmallerBits!(index);
		
		return nibbles[arrayIndex] >> 4 * smallerBits & 0xF;
	}

	public void Set(int x, int y, int z, int value) {
		int index = Index!(x, y, z);

		int arrayIndex = ArrayIndex!(index);
		int smallerBits = OccupiesSmallerBits!(index);

		int k = ~(15 << 4 * smallerBits);
		int l = (value & 0xF) << 4 * smallerBits;
		
		nibbles[arrayIndex] = (.) (nibbles[arrayIndex] & k | l);
	}

	public void Set(uint8* nibbles) {
		Internal.MemCpy(&this.nibbles, nibbles, 2048);
	}

	public void Clear() {
		Internal.MemSet(&nibbles, 0, 2048);
	}

	private static mixin Index(int x, int y, int z) {
	    y << 8 | z << 4 | x
	}

	private static mixin OccupiesSmallerBits(int i) {
	    i & 1
	}

	private static mixin ArrayIndex(int i) {
	    i >> 1
	}
}