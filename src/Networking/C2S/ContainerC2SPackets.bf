using System;

namespace Meteorite;

class SetSelectedSlotC2SPacket : C2SPacket {
	public const int32 ID = 0x28;

	private int slot;

	public this(int slot) : base(ID) {
		this.slot = slot;
	}

	public override void Write(NetBuffer buf) {
		buf.WriteShort((.) slot);
	}
}