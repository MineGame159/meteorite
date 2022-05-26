using System;

namespace Meteorite {
	class ChatMessageS2CPacket : S2CPacket {
		public const int32 ID = 0x0F;

		public Json text ~ _.Dispose();
		public int8 position;

		public this() : base(ID) {}

		public override void Read(NetBuffer packet) {
			String str = packet.ReadString();

			text = JsonParser.ParseString(str);
			position = packet.ReadByte();

			delete str;
		}
	}
}