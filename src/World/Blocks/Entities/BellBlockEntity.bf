using System;

namespace Meteorite {
	class BellBlockEntity : BlockEntity {
		public this(Vec3i pos) : base(BlockEntityTypes.BELL, pos) {}
	}
}