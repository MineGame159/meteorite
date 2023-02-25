using System;

namespace Meteorite;

class DisconnectS2CPacket : S2CPacket {
	public const int32 ID = 0x17;

	public Text reason ~ delete _;

	public this() : base(ID, .World, true) {}

	public override void Read(NetBuffer buf) {
		reason = buf.ReadText();
	}
}