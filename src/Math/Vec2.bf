using System;

namespace Meteorite {
	struct Vec2 : IEquatable, IEquatable<Vec2>, IHashable {
		public float x, y;

		public this(float x, float y) {
			this = ?;
			this.x = x;
			this.y = y;
		}

		public this() : this(default, default) {}

		public float Length => Math.Sqrt(x * x + y * y);

		public Self Normalize() {
			float l = Length;
			return .((.) (x / l), (.) (y / l));
		}

		public float Dot(Self v) => x * v.x + y * v.y;

		public bool Equals(Object o) => (o is Self) ? Equals((Self) o) : false;
		public bool Equals(Self v) => x == v.x && y == v.y;

		public int GetHashCode() => Utils.CombineHashCode(x.GetHashCode(), y.GetHashCode());

		public override void ToString(String str) => str.AppendF("[{:0.00}, {:0.00}]", x, y);

		public static Self operator+(Self lhs, Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y);
		public static Self operator-(Self lhs, Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y);
		public static Self operator*(Self lhs, Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y);
		public static Self operator/(Self lhs, Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y);
		public static Self operator%(Self lhs, Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y);

		[Commutable]
		public static Self operator+(Self lhs, float rhs) => .(lhs.x + rhs, lhs.y + rhs);
		public static Self operator-(Self lhs, float rhs) => .(lhs.x - rhs, lhs.y - rhs);
		public static Self operator-(float lhs, Self rhs) => .(lhs - rhs.x, lhs - rhs.y);
		[Commutable]
		public static Self operator*(Self lhs, float rhs) => .(lhs.x * rhs, lhs.y * rhs);
		public static Self operator/(Self lhs, float rhs) => .(lhs.x / rhs, lhs.y / rhs);
		public static Self operator/(float lhs, Self rhs) => .(lhs / rhs.x, lhs / rhs.y);
		public static Self operator%(Self lhs, float rhs) => .(lhs.x % rhs, lhs.y % rhs);
		public static Self operator%(float lhs, Self rhs) => .(lhs % rhs.x, lhs % rhs.y);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, float rhs) => lhs.Length > rhs;
		public static bool operator>(float lhs, Self rhs) => lhs > rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, float rhs) => lhs.Length < rhs;
		public static bool operator<(float lhs, Self rhs) => lhs < rhs.Length;
	}
}