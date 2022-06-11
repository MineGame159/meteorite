using System;

namespace Meteorite {
	class MessageC2SPacket : C2SPacket {
		public const int32 ID = 0x03;

		private String message ~ delete _;

		public this(StringView message) : base(ID) {
			this.message = new .(message);
		}

		public override void Write(NetBuffer buf) {
			buf.WriteString(message);
		}
	}
}