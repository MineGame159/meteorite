using System;

namespace Meteorite {
	class ClientSettingsC2SPacket : C2SPacket {
		public const int32 ID = 0x05;

		public int viewDistance;

		public this(int viewDistance) : base(ID) {
			this.viewDistance = viewDistance;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteString("en_GB"); // Locale
			buf.WriteByte((.) viewDistance); // View Distance
			buf.WriteVarInt(0); // Chat Mode (0 - enabled)
			buf.WriteBool(true); // Chat Colors
			buf.WriteUByte(0); // Displayed Skin Parts
			buf.WriteVarInt(1); // Main Hand (0 - left, 1 - right)
			buf.WriteBool(false); // Enable text filtering
			buf.WriteBool(true); // Allow server listings
		}
	}
}