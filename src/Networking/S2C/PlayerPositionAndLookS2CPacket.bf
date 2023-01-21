using System;

namespace Meteorite {
	class PlayerPositionAndLookS2CPacket : S2CPacket {
		public const int32 ID = 0x38;

		public double x, y, z;
		public float yaw, pitch;
		public uint8 flags;
		public int32 teleportId;
		public bool dismountVehicle;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			x = buf.ReadDouble();
			y = buf.ReadDouble() - me.world.dimension.minY;
			z = buf.ReadDouble();

			yaw = buf.ReadFloat();
			pitch = buf.ReadFloat();

			flags = buf.ReadUByte();
			teleportId = buf.ReadVarInt();
			dismountVehicle = buf.ReadBool();
		}

		public void Apply(ClientPlayerEntity player) {
			if (flags & 0x01 != 0) player.pos.x += x;
			else player.pos.x = x;

			if (flags & 0x02 != 0) player.pos.y += y;
			else player.pos.y = y;

			if (flags & 0x04 != 0) player.pos.z += z;
			else player.pos.z = z;

			if (flags & 0x08 != 0) player.pitch += pitch;
			else player.pitch = pitch;

			if (flags & 0x10 != 0) player.yaw += yaw;
			else player.yaw = yaw;
		}
	}
}