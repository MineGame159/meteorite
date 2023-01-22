using System;

namespace Meteorite;

class ItemStack {
	public Item item;
	public int count;

	public Tag? nbt ~ _?.Dispose();

	public this(Item item, int count, Tag? nbt) {
		this.item = item;
		this.count = count;
		this.nbt = nbt;
	}

	public bool IsEmpty => item == Items.AIR || count == 0;

	public void TransferTo(ItemStack itemStack) {
		itemStack.nbt?.Dispose();

		itemStack.item = item;
		itemStack.count = count;
		itemStack.nbt = nbt;

		item = Items.AIR;
		count = 0;
		nbt = null;
	}

	public void Clear() {
		item = Items.AIR;
		count = 0;

		nbt?.Dispose();
		nbt = null;
	}
}