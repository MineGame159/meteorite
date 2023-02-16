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

class Item : IRegistryEntry {
	private ResourceKey key;
	private int32 id;

	public int stackSize;
	public int durability;

	public ResourceKey Key => key;
	public int32 Id => id;

	[AllowAppend]
	public this(ResourceKey key, int32 id, ItemSettings settings) {
		ResourceKey _key = append .(key);

		this.key = _key;
		this.id = id;

		stackSize = settings.stackSize;
		durability = settings.durability;
	}
}