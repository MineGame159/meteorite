using System;

using Cacti;

namespace Meteorite {
	abstract class BlockEntity {
		public BlockEntityType type;
		public Vec3i pos;

		public this(BlockEntityType type, Vec3i pos) {
			this.type = type;
			this.pos = pos;
		}

		public void Load(Tag tag) {}
	}
}