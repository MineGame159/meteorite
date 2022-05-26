using System;

namespace Meteorite {
	class ConfirmTeleportC2SPacket : C2SPacket {
		public const int32 ID = 0x00;

		public int teleportId;

		public this(int teleportId) : base(ID) {
			this.teleportId = teleportId;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteVarInt((.) teleportId);
		}
	}
}