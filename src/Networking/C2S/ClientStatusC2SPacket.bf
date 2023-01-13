using System;

namespace Meteorite {
	class ClientStatusC2SPacket : C2SPacket {
		public const int32 ID = 0x06;

		public int actionId;

		public this(int actionId) : base(ID) {
			this.actionId = actionId;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteVarInt((.) actionId);
		}
	}
}