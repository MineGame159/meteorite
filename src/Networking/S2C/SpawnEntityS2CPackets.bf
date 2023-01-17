using System;

namespace Meteorite {
	class SpawnEntityS2CPacket : S2CPacket {
		public const int32 ID = 0x00;

		public int entityId;
		// UUID
		public EntityType type;
		public double x, y, z;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			entityId = buf.ReadVarInt();
			buf.Skip(16);
			type = EntityTypes.ENTITY_TYPES[buf.ReadVarInt()];
			x = buf.ReadDouble();
			y = buf.ReadDouble() - me.world.dimension.minY;
			z = buf.ReadDouble();
		}
	}
}