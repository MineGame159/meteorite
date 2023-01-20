using System;

namespace Cacti {
	typealias Vec3f = Vec3<float>;
	typealias Vec3d = Vec3<double>;
	typealias Vec3i = Vec3<int>;

	struct Vec3<T> : IEquatable, IEquatable<Self>, IHashable where T : var, operator T + T, operator T * T, operator T / T, operator T % T, IHashable {
		public static Self ZERO = .();

		public T x, y, z;

		public this(T x, T y, T z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public this(Vec4f v) : this(v.x, v.y, v.z) {}
		public this() : this(0, 0, 0) {}

		public bool IsZero => x == 0 && y == 0 && z == 0;

		public int IntX => (.) Math.Floor(x);
		public int IntY => (.) Math.Floor(y);
		public int IntZ => (.) Math.Floor(z);

		public double Length => Math.Sqrt(x * x + y * y + z * z);
		public double LengthSquared => x * x + y * y + z * z;

		public Vec2<T> XZ => .(x, z);
		public Vec2<T> YZ => .(y, z);
		public Vec2<T> XY => .(x, y);

		public Self Normalize() {
			double l = Length;
			return .((.) (x / l), (.) (y / l), (.) (z / l));
		}

		public Self Cross(Self v) => .(y * v.z - v.y * z, z * v.x - v.z * x, x * v.y - v.x * y);
		public T Dot(Self v) => x * v.x + y * v.y + z * v.z;

		public Self Clamp(T min, T max) => .(Math.Clamp(x, min, max), Math.Clamp(y, min, max), Math.Clamp(z, min, max));
		public Self Lerp(T delta, Self end) => .(Utils.Lerp(delta, x, end.x), Utils.Lerp(delta, y, end.y), Utils.Lerp(delta, z, end.z));

		public Self Min(Self v) => .(Math.Min(x, v.x), Math.Min(y, v.y), Math.Min(z, v.z));
		public Self Max(Self v) => .(Math.Max(x, v.x), Math.Max(y, v.y), Math.Max(z, v.z));

		public bool Equals(Object o) => (o is Self) ? Equals((Self) o) : false;
		public bool Equals(Self v) => x == v.x && y == v.y && z == v.z;

		public int GetHashCode() {
			int hash = Utils.CombineHashCode(x.GetHashCode(), y.GetHashCode());
			return Utils.CombineHashCode(hash, z.GetHashCode());
		}

		public override void ToString(String str) => str.AppendF("[{:0.00}, {:0.00}, {:0.00}]", x, y, z);

		public static Self operator+(Self lhs, Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
		public static Self operator-(Self lhs, Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);
		public static Self operator*(Self lhs, Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);
		public static Self operator/(Self lhs, Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z);
		public static Self operator%(Self lhs, Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z);

		[Commutable]
		public static Self operator+(Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs);
		public static Self operator-(Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs);
		public static Self operator-(T lhs, Self rhs) => .(lhs - rhs.x, lhs - rhs.y, lhs - rhs.z);
		[Commutable]
		public static Self operator*(Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs);
		public static Self operator/(Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs);
		public static Self operator/(T lhs, Self rhs) => .(lhs / rhs.x, lhs / rhs.y, lhs / rhs.z);
		public static Self operator%(Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs);
		public static Self operator%(T lhs, Self rhs) => .(lhs % rhs.x, lhs % rhs.y, lhs % rhs.z);

		//public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y, -rhs.z);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, T rhs) => lhs.Length > rhs;
		public static bool operator>(T lhs, Self rhs) => lhs > rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, T rhs) => lhs.Length < rhs;
		public static bool operator<(T lhs, Self rhs) => lhs < rhs.Length;
	}

	extension Vec3<T> where T : Float {
		public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y, -rhs.z);
	}
}