using System;

using Cacti;

namespace Meteorite;

static class RayUtils {
	public const double EPSILON = 0.000001;

	private enum Collision {
		X,
		Z,
		Y
	}

	private struct Rect : this(Vec2d min, Vec2d max) {
		public bool Interects(Rect rect) {
			Vec2d thisHalf = (this.max - this.min) / 2;
			Vec2d rectHalf = (rect.max - rect.min) / 2;
					
			Vec2d thisPos = this.min + thisHalf;
			Vec2d rectPos = rect.min + rectHalf;

			double dx = rectPos.x - thisPos.x;
			double px = (thisHalf.x + rectHalf.x) - Math.Abs(dx);
			if (px <= 0) return false;

			double dy = rectPos.y - thisPos.y;
			double py = (thisHalf.y + rectHalf.y) - Math.Abs(dy);
			if (py <= 0) return false;

			return true;
		}
	}

	public static bool BoundingBoxIntersectionCheckNew(AABB moving, Vec3d rayStart, Vec3d rayDirection, AABB collidableStatic, Vec3d staticCollidableOffset, SweepResult finalResult) {
		Vec3d originalMovMin = moving.min - .(moving.Width / 2, 0, moving.Depth / 2);
		Vec3d originalMovMax = moving.max - .(moving.Width / 2, 0, moving.Depth / 2);

		Vec3d newMovMin = originalMovMin + rayDirection;
		Vec3d newMovMax = originalMovMax + rayDirection;

		Vec3d boxMin = collidableStatic.min + staticCollidableOffset - rayStart;
		Vec3d boxMax = collidableStatic.max + staticCollidableOffset - rayStart;

		Collision collision = .X;
		double progress = double.MaxValue;

		// X+
		if (rayDirection.x > 0 && newMovMax.x > boxMin.x) {
			Rect movX = .(newMovMin.YZ, newMovMax.YZ);
			Rect boxX = .(boxMin.YZ, boxMax.YZ);

			if (movX.Interects(boxX)) {
				double xProgress = Math.Abs(boxMin.x - originalMovMax.x) / rayDirection.x;

				if (xProgress < progress) {
					collision = .X;
					progress = xProgress;
				}
			}
		}

		// X-
		if (rayDirection.x < 0 && newMovMin.x < boxMax.x) {
			Rect movX = .(newMovMin.YZ, newMovMax.YZ);
			Rect boxX = .(boxMin.YZ, boxMax.YZ);

			if (movX.Interects(boxX)) {
				double xProgress = Math.Abs(boxMax.x - originalMovMin.x) / -rayDirection.x;

				if (xProgress < progress) {
					collision = .X;
					progress = xProgress;
				}
			}
		}

		// Y+
		if (rayDirection.y > 0 && newMovMax.y > boxMin.y) {
			Rect movY = .(newMovMin.XZ, newMovMax.XZ);
			Rect boxY = .(boxMin.XZ, boxMax.XZ);

			if (movY.Interects(boxY)) {
				double yProgress = Math.Abs(boxMin.y - originalMovMax.y) / rayDirection.y;

				if (yProgress < progress) {
					collision = .Y;
					progress = yProgress;
				}
			}
		}
		
		// Z-
		if (rayDirection.z < 0 && newMovMin.z < boxMax.z) {
			Rect movZ = .(newMovMin.XY, newMovMax.XY);
			Rect boxZ = .(boxMin.XY, boxMax.XY);

			if (movZ.Interects(boxZ)) {
				double zProgress = Math.Abs(boxMax.z - originalMovMin.z) / -rayDirection.z;

				if (zProgress < progress) {
					collision = .Z;
					progress = zProgress;
				}
			}
		}

		// Z+
		if (rayDirection.z > 0 && newMovMax.z > boxMin.z) {
			Rect movZ = .(newMovMin.XY, newMovMax.XY);
			Rect boxZ = .(boxMin.XY, boxMax.XY);

			if (movZ.Interects(boxZ)) {
				double zProgress = Math.Abs(boxMin.z - originalMovMax.z) / rayDirection.z;

				if (zProgress < progress) {
					collision = .Z;
					progress = zProgress;
				}
			}
		}

		// Y-
		if (rayDirection.y < 0 && newMovMin.y < boxMax.y) {
			Rect movY = .(newMovMin.XZ, newMovMax.XZ);
			Rect boxY = .(boxMin.XZ, boxMax.XZ);

			if (movY.Interects(boxY)) {
				double yProgress = Math.Abs(boxMax.y - originalMovMin.y) / -rayDirection.y;

				if (yProgress < progress) {
					collision = .Y;
					progress = yProgress;
				}
			}
		}

		// Return
		progress *= 0.99999;

		if (progress >= 0 && progress <= finalResult.res) {
			finalResult.normalX = collision == .X ? 1 : 0;
			finalResult.normalY = collision == .Y ? 1 : 0;
			finalResult.normalZ = collision == .Z ? 1 : 0;

			finalResult.res = progress;

			return true;
		}

		return false;
	}
}