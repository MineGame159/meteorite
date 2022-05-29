using System;

namespace Meteorite {
	struct AABB {
		public Vec3d min, max;

		public this(Vec3d min, Vec3d max) {
			this.min = min;
			this.max = max;
		}

		public AABB Expand(Vec3d vec) {
			Vec3d min = min;
			Vec3d max = max;

			if (vec.x < 0) min.x -= vec.x;
			else max.x += vec.x;

			if (vec.y < 0) min.y -= vec.y;
			else max.y += vec.y;

			if (vec.z < 0) min.z -= vec.z;
			else max.z += vec.z;

			return .(min, max);
		}

		//public bool Intersects(double x1, double y1, double z1, double x2, double y2, double z2) => min.x < x1 && min.x < x2 && max.x > x1 && min.y < y2 && max.y > y1 && min.z < z2 && max.z > z1;
		public bool Intersects(double x1, double y1, double z1, double x2, double y2, double z2) => !(max.x < x1 || max.y < y1 || max.z < z1 || min.x > x2 || min.y > y2 || min.z > z2);
		public bool Intersects(Vec3d min, Vec3d max) => Intersects(Math.Min(min.x, max.x), Math.Min(min.y, max.y), Math.Min(min.z, max.z), Math.Max(min.x, max.x), Math.Max(min.y, max.y), Math.Max(min.z, max.z));
		public bool Intersects(AABB aabb) => Intersects(aabb.min, aabb.max);
	}
}