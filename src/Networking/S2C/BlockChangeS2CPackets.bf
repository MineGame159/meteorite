using System;

namespace Meteorite {
	class BlockChangeS2CPacket : S2CPacket {
		public const int32 ID = 0x0C;

		public Vec3i pos;
		public BlockState blockState;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			pos = buf.ReadPosition();
			pos.y -= me.world.minY;

			blockState = Blocks.BLOCKSTATES[buf.ReadVarInt()];
		}
	}

	class MultiBlockChangeS2CPacket : S2CPacket {
		public const int32 ID = 0x3F;

		public Vec3i sectionPos;
		public Block[] blocks ~ delete _;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			int64 section = buf.ReadLong();
			sectionPos = .(section >> 42, section << 44 >> 44, section << 22 >> 42);
			sectionPos.y -= me.world.minY / Section.SIZE;

			buf.ReadBool();

			blocks = new .[buf.ReadVarInt()];
			for (var block in ref blocks) {
				int64 blockRaw = buf.ReadVarLong();
				int16 posRaw = (.) (blockRaw & 4095);

				block.pos = .(posRaw >> 8 & 15, (posRaw & 15), posRaw >> 4 & 15);
				block.blockState = Blocks.BLOCKSTATES[blockRaw >> 12];
			}
		}

		public struct Block {
			public Vec3i pos;
			public BlockState blockState;
		}
	}
}