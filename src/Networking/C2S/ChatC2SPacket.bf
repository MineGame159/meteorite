using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class ChatC2SPacket : C2SPacket {
		public const int32 CHAT_ID = 0x05;
		public const int32 COMMAND_ID = 0x04;

		private static Random RANDOM = new .() ~ delete _;

		private String message ~ delete _;

		public this(StringView message) : base(message.StartsWith('/') ? COMMAND_ID : CHAT_ID) {
			this.message = new .(message, 0, Math.Min(message.Length, 257));
		}

		public override void Write(NetBuffer buf) {
			buf.EnsureCapacity(2048);

			int32 length = (.) Math.Min(message.Length - (id == COMMAND_ID ? 1 : 0), 256);
			buf.WriteVarInt(length);
			buf.Write((.) &message.Ptr[id == COMMAND_ID ? 1 : 0], length);

			buf.WriteLong(Utils.UnixTimeEpoch);
			buf.WriteLong(RANDOM.NextI64());

			if (id == COMMAND_ID) {
				buf.WriteVarInt(0);
			}
			else {
				buf.WriteBool(false);
			}

			buf.WriteVarInt(0);
			for (int i < Utils.PositiveCeilDiv(20, 8)) buf.WriteByte(0);
		}
	}
}