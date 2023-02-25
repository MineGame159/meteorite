using System;

namespace Meteorite;

class ChangeGameStateS2CPacket : S2CPacket {
	public const int32 ID = 0x1C;

	public uint8 reason;
	public float value;

	public this() : base(ID, .Player) {}

	public override void Read(NetBuffer buf) {
		reason = buf.ReadUByte();
		value = buf.ReadFloat();
	}
}