using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;

namespace Meteorite {
	class VoxelShape {
		public static VoxelShape EMPTY = new .() ~ delete _;

		private List<AABB> boxes = new .() ~ delete _;

		public this() {
		}

		public VoxelShape Add(Vec3d min, Vec3d max) {
			boxes.Add(.(min, max));
			return this;
		}

		public AABB GetBoundingBox() {
			AABB bounding = .(.(1, 1, 1), .());

			for (let aabb in boxes) {
				if (aabb.min.x < bounding.min.x) bounding.min.x = aabb.min.x;
				if (aabb.min.y < bounding.min.y) bounding.min.y = aabb.min.y;
				if (aabb.min.z < bounding.min.z) bounding.min.z = aabb.min.z;

				if (aabb.max.x > bounding.max.x) bounding.max.x = aabb.max.x;
				if (aabb.max.y > bounding.max.y) bounding.max.y = aabb.max.y;
				if (aabb.max.z > bounding.max.z) bounding.max.z = aabb.max.z;
			}

			return bounding;
		}

		public bool IntersectBoxSwept(Vec3d rayStart, Vec3d rayDirection, Vec3d shapePos, AABB moving, SweepResult finalResult) {
		    bool hitBlock = false;

			for (AABB aabb in boxes) {
			    // Update final result if the temp result collision is sooner than the current final result
			    if (RayUtils.BoundingBoxIntersectionCheckNew(moving, rayStart, rayDirection, aabb, shapePos, finalResult)) {
			        finalResult.collidedShapePosition = shapePos;
			    }

			    hitBlock = true;
			}

			return hitBlock;
		}

		public BlockHitResult Raycast(Vec3d start, Vec3d end, Vec3i pos) {
			if (boxes.IsEmpty) return null;

			Vec3d vec = end - start;
			if (vec.LengthSquared < 1.0E-7) return null;

			Vec3d vec2 = start + (vec * 0.001);
			// TODO

			return AABB.Raycast(boxes, start, end, pos);
		}

		public static VoxelShape Block() => new VoxelShape().Add(.(0, 0, 0), .(1, 1, 1));
	}
}