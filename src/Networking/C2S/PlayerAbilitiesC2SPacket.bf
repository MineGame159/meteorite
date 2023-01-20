using System;

namespace Meteorite;

class PlayerAbilitiesC2SPacket : C2SPacket {
	public const int32 ID = 0x1B;

	public int8 flags;

	public this(PlayerAbilities abilities) : base(ID) {
		if (abilities.flying) {
			flags |= 2;
		}
	}

	public override void Write(NetBuffer buf) {
		buf.WriteByte(flags);
	}
}