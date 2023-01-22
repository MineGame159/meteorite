using System;

namespace Meteorite;

class SetContainerItemsS2CPacket : S2CPacket {
	public const int32 ID = 0x10;

	public int windowId;
	public int stateId;

	public ItemStack[] items ~ DeleteContainerAndItems!(_);

	public this() : base(ID, .Player) {}

	public override void Read(NetBuffer buf) {
		windowId = buf.ReadUByte();
		stateId = buf.ReadVarInt();

		int count = buf.ReadVarInt();
		items = new .[count];

		for (int i < count) {
			items[i] = SetContainerItemS2CPacket.ReadItemStack(buf);
		}
	}
}

class SetContainerItemS2CPacket : S2CPacket {
	public const int32 ID = 0x12;

	public int windowId;
	public int stateId;

	public int slot;
	public ItemStack itemStack ~ delete _;

	public this() : base(ID, .Player) {}

	public override void Read(NetBuffer buf) {
		windowId = buf.ReadUByte();
		stateId = buf.ReadVarInt();

		slot = buf.ReadShort();
		itemStack = ReadItemStack(buf);
	}

	public static ItemStack ReadItemStack(NetBuffer buf) {
		bool present = buf.ReadBool();
		if (!present) return null;

		Item item = Items.ITEMS[buf.ReadVarInt()];
		int stackSize = buf.ReadByte();

		Tag? nbt;
		switch (buf.ReadNbt()) {
		case .Ok(let val):	nbt = val;
		case .Err:			nbt = null;
		}

		return new .(item, stackSize, nbt);
	}
}

class SetSelectedSlotS2CPacket : S2CPacket {
	public const int32 ID = 0x49;

	public int slot;

	public this() : base(ID, .World) {}

	public override void Read(NetBuffer buf) {
		slot = buf.ReadByte();
	}
}