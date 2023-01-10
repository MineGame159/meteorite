using System;

using Cacti;

namespace Meteorite {
	class ChestBlockEntity : BlockEntity {
		public this(Vec3i pos) : base(BlockEntityTypes.CHEST, pos) {}
	}
}