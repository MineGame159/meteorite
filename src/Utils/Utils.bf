using System;

using Cacti;

namespace Meteorite {
	enum Direction {
		case Up;
		case Down;
		case East; // Východ
		case North; // Sever
		case West; // Západ
		case South; // Juh

		public Vec3i GetOffset() {
			switch (this) {
			case .Up:    return .(0, 1, 0);
			case .Down:  return .(0, -1, 0);
			case .East:  return .(1, 0, 0);
			case .West:  return .(-1, 0, 0);
			case .North: return .(0, 0, -1);
			case .South: return .(0, 0, 1);
			}
		}

		public Direction GetOpposite() {
			switch (this) {
			case .Up:    return .Down;
			case .Down:  return .Up;
			case .East:  return .West;
			case .West:  return .East;
			case .North: return .South;
			case .South: return .North;
			}
		}

		public int Data2D { get {
			switch (this) {
			case .Up, .Down: return -1;

			case .East:  return 3;
			case .North: return 2;
			case .West:  return 1;
			case .South: return 0;
			}
		} }

		public int YRot => (Data2D & 3) * 90;

		public static Direction GetFacing(Vec3d vec) {
			Direction direction = .North;
			double f = float.MinValue;

			for (Direction direction2 in Enum.GetValues<Direction>()) {
				Vec3i offset = direction2.GetOffset();
			    double g = vec.x * offset.x + vec.y * offset.y + vec.z * offset.z;
			    if (!(g > f)) continue;
			    f = g;
			    direction = direction2;
			}

			return direction;
		}
	}
}