using System;

namespace Meteorite {
	class ChatMessageS2CPacket : S2CPacket {
		public const int32 ID = 0x0F;

		public Text text ~ delete _;
		public int8 position;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer packet) {
			String str = packet.ReadString();
			Json json = JsonParser.ParseString(str);

			text = .Parse(json);
			position = packet.ReadByte();

			json.Dispose();
			delete str;
		}
	}
}