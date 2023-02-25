using System;
using System.Collections;

using Cacti;

namespace Meteorite;

struct AABB {
	public Vec3d min, max;

	public this(Vec3d min, Vec3d max) {
		this.min = min;
		this.max = max;
	}

	public double Width => max.x - min.x;
	public double Height => max.y - min.y;
	public double Depth => max.z - min.z;

	public Vec3d Size => .(Width, Height, Depth);
	public Vec3d Center => min + max / 2;

	public AABB OffsetA(Vec3d pos) => .(pos + min, pos + max);
	public AABB Offset(Vec3i pos) => .(.(pos.x, pos.y, pos.z) + min, .(pos.x, pos.y, pos.z) + max);

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

	public static BlockHitResult Raycast(List<AABB> boxes, Vec3d from, Vec3d to, Vec3i pos) {
		double ds = 1;
		Direction? direction = null;

		double d = to.x - from.x;
		double e = to.y - from.y;
		double f = to.z - from.z;

		for (let aabb in boxes) {
			direction = TraceCollisionSide(aabb.Offset(pos), from, ref ds, direction, d, e, f);
		}

		if (direction == null) return null;
		double g = ds;
		return new .(from + .(g * d, g * e, g * f), pos, direction.Value, false);
	}

	private static Direction? TraceCollisionSide(AABB aabb, Vec3d intersectingVector, ref double traceDistanceResult, Direction? approachDirection, double deltaX, double deltaY, double deltaZ) {
		var approachDirection;

		if (deltaX > 1.0E-7) {
		    approachDirection = TraceCollisionSide(ref traceDistanceResult, approachDirection, deltaX, deltaY, deltaZ, aabb.min.x, aabb.min.y, aabb.max.y, aabb.min.z, aabb.max.z, .West, intersectingVector.x, intersectingVector.y, intersectingVector.z);
		} else if (deltaX < -1.0E-7) {
		    approachDirection = TraceCollisionSide(ref traceDistanceResult, approachDirection, deltaX, deltaY, deltaZ, aabb.max.x, aabb.min.y, aabb.max.y, aabb.min.z, aabb.max.z, .East, intersectingVector.x, intersectingVector.y, intersectingVector.z);
		}

		if (deltaY > 1.0E-7) {
		    approachDirection = TraceCollisionSide(ref traceDistanceResult, approachDirection, deltaY, deltaZ, deltaX, aabb.min.y, aabb.min.z, aabb.max.z, aabb.min.x, aabb.max.x, .Down, intersectingVector.y, intersectingVector.z, intersectingVector.x);
		} else if (deltaY < -1.0E-7) {
		    approachDirection = TraceCollisionSide(ref traceDistanceResult, approachDirection, deltaY, deltaZ, deltaX, aabb.max.y, aabb.min.z, aabb.max.z, aabb.min.x, aabb.max.x, .Up, intersectingVector.y, intersectingVector.z, intersectingVector.x);
		}

		if (deltaZ > 1.0E-7) {
		    approachDirection = TraceCollisionSide(ref traceDistanceResult, approachDirection, deltaZ, deltaX, deltaY, aabb.min.z, aabb.min.x, aabb.max.x, aabb.min.y, aabb.max.y, .North, intersectingVector.z, intersectingVector.x, intersectingVector.y);
		} else if (deltaZ < -1.0E-7) {
		    approachDirection = TraceCollisionSide(ref traceDistanceResult, approachDirection, deltaZ, deltaX, deltaY, aabb.max.z, aabb.min.x, aabb.max.x, aabb.min.y, aabb.max.y, .South, intersectingVector.z, intersectingVector.x, intersectingVector.y);
		}

		return approachDirection;
	}

	private static Direction? TraceCollisionSide(ref double traceDistanceResult, Direction? approachDirection, double deltaX, double deltaY, double deltaZ, double begin, double minX, double maxX, double minZ, double maxZ, Direction resultDirection, double startX, double startY, double startZ) {
	    double d = (begin - startX) / deltaX;
	    double e = startY + d * deltaY;
	    double f = startZ + d * deltaZ;

	    if (0.0 < d && d < traceDistanceResult && minX - 1.0E-7 < e && e < maxX + 1.0E-7 && minZ - 1.0E-7 < f && f < maxZ + 1.0E-7) {
	        traceDistanceResult = d;
	        return resultDirection;
	    }

	    return approachDirection;
	}
}