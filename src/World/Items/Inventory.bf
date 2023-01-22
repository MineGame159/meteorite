using System;
using System.Collections;

namespace Meteorite;

class Inventory {
	public ItemStack[46] items;
	public int selectedSlot;

	public this() {
		for (var item in ref items) {
			item = new .(Items.AIR, 0, null);
		}
	}

	public ~this() {
		for (let item in items) {
			delete item;
		}
	}

	public ItemStack GetMain(int i) => items[9 + i];
	public ItemStack GetHotbar(int i) => items[36 + i];
	public ItemStack GetOffhand() => items[45];
	public ItemStack GetArmor(int i) => items[5 + i];
}