using System;

namespace Meteorite;

class ItemSettings {
	public int stackSize = 64;
	public int durability = 0;

	public Self StackSize(int stackSize) {
		this.stackSize = stackSize;
		return this;
	}

	public Self Durability(int durability) {
		this.durability = durability;
		return this;
	}
}

class Item {
	public String id ~ delete _;
	public int32 rawId;

	public int stackSize;
	public int durability;

	public this(StringView id, int32 rawId, ItemSettings settings) {
		this.id = new .(id);
		this.rawId = rawId;

		stackSize = settings.stackSize;
		durability = settings.durability;
	}
}