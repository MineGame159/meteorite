using System;

namespace Meteorite;

class SetXPS2CPacket : S2CPacket {
	public const int32 ID = 0x52;

	public int xpTotal;
	public int xpLevel;
	public float xpProgress;

	public this() : base(ID, .Player) {}

	public override void Read(NetBuffer buf) {
		xpProgress = buf.ReadFloat();
		xpLevel = buf.ReadVarInt();
		xpTotal = buf.ReadVarInt();
	}
}