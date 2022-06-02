using System;
using System.Collections;

namespace Meteorite {
	class BlockEntityType {
		public typealias Factory = delegate BlockEntity(Vec3i);

		public String id ~ delete _;
		public Block[] blocks ~ delete _;

		private Factory factory ~ delete _;

		public this(StringView id, Block[] blocks, Factory factory) {
			this.id = new .(id);
			this.blocks = blocks;
			this.factory = factory;
		}

		public BlockEntity Create(Vec3i pos) {
			return factory != null ? factory(pos) : null;
		}
	}
}