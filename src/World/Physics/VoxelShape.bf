using System;

namespace Meteorite {
	class VoxelShape {
		public static VoxelShape EMPTY = new .(new .(1), .(), .()) ~ delete _;

		private BitSet set ~ delete _;
		private Vec3d min, max;

		public this(BitSet set, Vec3d min, Vec3d max) {
			this.set = set;
			this.min = min;
			this.max = max;
		}

		public static VoxelShape Box(int x1, int y1, int z1, int x2, int y2, int z2) {
			BitSet set = new .(1);
			set.Set(0);

			return new .(set, .(x1 / 16.0, y1 / 16.0, z1 / 16.0), .(x2 / 16.0, y2 / 16.0, z2 / 16.0));
		}

		public static VoxelShape Block() => Box(0, 0, 0, 1, 1, 1);
	}
}