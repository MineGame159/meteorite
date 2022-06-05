using System;

namespace Meteorite {
	typealias Vec2f = Vec2<float>;
	typealias Vec2d = Vec2<double>;

	struct Vec2<T> : IEquatable, IEquatable<Self>, IHashable where T : var, operator T + T, operator T * T, operator T / T, operator T % T, IHashable {
		public T x, y;

		public this(T x, T y) {
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
		public static Self operator+(Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs);
		public static Self operator-(Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs);
		public static Self operator-(T lhs, Self rhs) => .(lhs - rhs.x, lhs - rhs.y);
		[Commutable]
		public static Self operator*(Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs);
		public static Self operator/(Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs);
		public static Self operator/(T lhs, Self rhs) => .(lhs / rhs.x, lhs / rhs.y);
		public static Self operator%(Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs);
		public static Self operator%(T lhs, Self rhs) => .(lhs % rhs.x, lhs % rhs.y);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, T rhs) => lhs.Length > rhs;
		public static bool operator>(T lhs, Self rhs) => lhs > rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, T rhs) => lhs.Length < rhs;
		public static bool operator<(T lhs, Self rhs) => lhs < rhs.Length;
	}
}