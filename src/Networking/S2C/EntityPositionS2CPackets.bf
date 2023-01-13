using System;

using Cacti;

namespace Meteorite {
	abstract class BaseEntityPositionS2CPacket : S2CPacket {
		public int entityId;

		public bool hasPosition;
		public int16 deltaX, deltaY, deltaZ;

		public bool teleport;
		public double x, y, z;

		public bool hasRotation;
		public float yaw, pitch;

		public this(int32 id) : base(id, .World) {}

		public override void Read(NetBuffer buf) {
			entityId = buf.ReadVarInt();
		}

		protected void ReadPosition(NetBuffer buf) {
			hasPosition = true;
			deltaX = buf.ReadShort();
			deltaY = buf.ReadShort();
			deltaZ = buf.ReadShort();
		}

		protected void ReadRotation(NetBuffer buf) {
			hasRotation = true;
			yaw = buf.ReadAngle();
			pitch = buf.ReadAngle();
		}

		public Vec3d GetPos(Entity entity) {
			if (teleport) return .(x, y, z);

			double x = deltaX == 0 ? entity.trackedPos.x : DecodePacketCoordinate(EncodePacketCoordinate(entity.trackedPos.x) + (int64) deltaX);
			double y = deltaY == 0 ? entity.trackedPos.y : DecodePacketCoordinate(EncodePacketCoordinate(entity.trackedPos.y) + (int64) deltaY);
			double z = deltaZ == 0 ? entity.trackedPos.z : DecodePacketCoordinate(EncodePacketCoordinate(entity.trackedPos.z) + (int64) deltaZ);

			return .(x, y, z);
		}

		private static double DecodePacketCoordinate(int64 coord) => coord / 4096.0;
		private static int64 EncodePacketCoordinate(double coord) => Utils.Lfloor(coord * 4096.0);
	}

	class EntityPositionS2CPacket : BaseEntityPositionS2CPacket {
		public const int32 ID = 0x27;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			base.Read(buf);

			ReadPosition(buf);
		}
	}

	class EntityRotationS2CPacket : BaseEntityPositionS2CPacket {
		public const int32 ID = 0x29;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			base.Read(buf);

			ReadRotation(buf);
		}
	}

	class EntityPositionAndRotationS2CPacket : BaseEntityPositionS2CPacket {
		public const int32 ID = 0x28;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			base.Read(buf);

			ReadPosition(buf);
			ReadRotation(buf);
		}
	}

	class EntityTeleportS2CPacket : BaseEntityPositionS2CPacket {
		public const int32 ID = 0x64;

		public bool onGround;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			base.Read(buf);

			hasPosition = true;
			teleport = true;
			x = buf.ReadDouble();
			y = buf.ReadDouble() - me.world.minY;
			z = buf.ReadDouble();

			ReadRotation(buf);

			onGround = buf.ReadBool();
		}
	}
}