using System;

namespace Meteorite {
	class PlayerPositionAndLookS2CPacket : S2CPacket {
		public const int32 ID = 0x38;

		public double x, y, z;
		public float yaw, pitch;
		public uint8 flags;
		public int32 teleportId;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			x = buf.ReadDouble();
			y = buf.ReadDouble() - me.world.minY + 2;
			z = buf.ReadDouble();

			yaw = buf.ReadFloat();
			pitch = buf.ReadFloat();

			flags = buf.ReadUByte();
			teleportId = buf.ReadVarInt();
		}
	}
}