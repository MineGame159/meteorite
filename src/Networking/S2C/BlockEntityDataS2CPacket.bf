using System;

namespace Meteorite {
	class BlockEntityDataS2CPacket : S2CPacket {
		public const int32 ID = 0x0A;

		public Vec3i pos;
		public BlockEntityType type;

		public bool remove;
		public Tag data ~ _.Dispose();

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			pos = buf.ReadPosition();
			type = BlockEntityTypes.TYPES[buf.ReadVarInt()];

			Result<Tag> result = buf.ReadNbt();
			if (result case .Ok(let tag)) data = tag;
			else remove = true;
		}
	}
}