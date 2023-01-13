using System;

namespace Meteorite {
	class PlayerPositionC2SPacket : C2SPacket {
		public bool hasPosition;
		public double x, y, z;

		public bool hasRotation;
		public float yaw, pitch;

		public bool onGround;

		public this(ClientPlayerEntity player, bool position, bool rotation) : base((position && rotation) ? 0x14 : (position ? 0x13 : 0x15)) {
			if (position) {
				hasPosition = true;
				this.x = player.pos.x;
				this.y = player.pos.y + me.world.minY;
				this.z = player.pos.z;
			}

			if (rotation) {
				hasRotation = true;
				this.yaw = player.yaw;
				this.pitch = player.pitch;
			}
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
	}
}