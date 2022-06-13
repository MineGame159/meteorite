using System;

namespace Meteorite {
	class ChatMessageS2CPacket : S2CPacket {
		public const int32 ID = 0x0F;

		public Text text ~ delete _;
		public int8 position;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			text = buf.ReadText();
			position = buf.ReadByte();
		}
	}
}