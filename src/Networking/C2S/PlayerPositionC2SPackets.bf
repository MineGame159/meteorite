using System;

namespace Meteorite {
	class PlayerPositionC2SPacket : C2SPacket {
		public const int32 POSITION_ID = 0x13;
		public const int32 POSITION_ROTATION_ID = 0x14;
		public const int32 ROTATION_ID = 0x15;
		public const int32 ON_GROUND_ID = 0x16;

		public bool hasPosition;
		public double x, y, z;

		public bool hasRotation;
		public float yaw, pitch;

		public bool onGround;

		public this(ClientPlayerEntity player, bool position, bool rotation) : base(GetId(position, rotation)) {
			if (position) {
				hasPosition = true;
				x = player.pos.x;
				y = player.pos.y + me.world.dimension.minY;
				z = player.pos.z;
			}

			if (rotation) {
				hasRotation = true;
				yaw = player.yaw;
				pitch = player.pitch;
			}

			onGround = player.onGround;
		}

		public override void Write(NetBuffer buf) {
			if (hasPosition) {
				buf.WriteDouble(x);
				buf.WriteDouble(y);
				buf.WriteDouble(z);
			}

			if (hasRotation) {
				buf.WriteFloat(yaw);
				buf.WriteFloat(pitch);
			}

			buf.WriteBool(onGround);
		}

		private static int32 GetId(bool position, bool rotation) {
			if (position && rotation) return POSITION_ROTATION_ID;
			if (position) return POSITION_ID;
			if (rotation) return ROTATION_ID;

			return ON_GROUND_ID;
		}
	}
}