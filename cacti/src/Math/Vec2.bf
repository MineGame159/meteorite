using System;

namespace Cacti {
	typealias Vec2f = Vec2<float>;
	typealias Vec2d = Vec2<double>;
	typealias Vec2i = Vec2<int>;

	struct Vec2<T> : IEquatable, IEquatable<Self>, IHashable where T : var, operator T + T, operator T * T, operator T / T, operator T % T, IHashable {
		public static Self ZERO = .();

		public T x, y;

		public this(T x, T y) {
			this.x = x;
			this.y = y;
		}

		public this(Vec4<T> v) : this(v.x, v.y) {}
		public this(Vec3<T> v) : this(v.x, v.y) {}
		public this() : this(0, 0) {}

		public T this[int index] {
			get {
				return index == 1 ? y : x;
			}
			set mut {
				if (index == 1) y = value;
				else x = value;
			}
		}

		public bool IsZero => x == 0 && y == 0;

		public int IntX => (.) Math.Floor(x);
		public int IntY => (.) Math.Floor(y);

		public double Length => Math.Sqrt(x * x + y * y);
		public double LengthSquared => x * x + y * y;

		public Self Normalize() {
			double l = Length;
			return .((.) (x / l), (.) (y / l));
		}

		public float Dot(Self v) => x * v.x + y * v.y;

		public Self Clamp(T min, T max) => .(Math.Clamp(x, min, max), Math.Clamp(y, min, max));
		public Self Lerp(T delta, Self end) => .(Utils.Lerp(delta, x, end.x), Utils.Lerp(delta, y, end.y));

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

		//public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, T rhs) => lhs.Length > rhs;
		public static bool operator>(T lhs, Self rhs) => lhs > rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, T rhs) => lhs.Length < rhs;
		public static bool operator<(T lhs, Self rhs) => lhs < rhs.Length;
	}

	extension Vec2<int> {
		public Vec2<float> ToFloat => .(x, y);
	}
}