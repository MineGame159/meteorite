using System;

namespace Meteorite {
	typealias Vec3i = Vec3<int>;
	typealias Vec3f = Vec3<float>;
	typealias Vec3d = Vec3<double>;

	struct Vec3<T> : IEquatable, IEquatable<Self>, IHashable where T : var, operator T + T, operator T - T, operator T * T, operator T / T, operator T % T, operator -T, IHashable {
		public T x, y, z;

		public this(T x, T y, T z) {
			this = ?;
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public this(Vec4 v) : this(v.x, v.y, v.z) {}
		public this() : this(0, 0, 0) {}

		public double Length => Math.Sqrt(x * x + y * y + z * z);
		public double LengthSquared => x * x + y * y + z * z;

		public Self Normalize() {
			double l = Length;
			return .((.) (x / l), (.) (y / l), (.) (z / l));
		}

		public Self Cross(Self v) => .(y * v.z - v.y * z, z * v.x - v.z * x, x * v.y - v.x * y);
		public float Dot(Self v) => x * v.x + y * v.y + z * v.z;
		public Self Lerp(double delta, Self start) => .(Utils.Lerp(delta, start.x, x), Utils.Lerp(delta, start.y, y), Utils.Lerp(delta, start.z, z));

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
		public static Self operator+(Self lhs, float rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs);
		public static Self operator-(Self lhs, float rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs);
		public static Self operator-(float lhs, Self rhs) => .(lhs - rhs.x, lhs - rhs.y, lhs - rhs.z);
		[Commutable]
		public static Self operator*(Self lhs, float rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs);
		public static Self operator/(Self lhs, float rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs);
		public static Self operator/(float lhs, Self rhs) => .(lhs / rhs.x, lhs / rhs.y, lhs / rhs.z);
		public static Self operator%(Self lhs, float rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs);
		public static Self operator%(float lhs, Self rhs) => .(lhs % rhs.x, lhs % rhs.y, lhs % rhs.z);

		public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y, -rhs.z);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, float rhs) => lhs.Length > rhs;
		public static bool operator>(float lhs, Self rhs) => lhs > rhs.Length;
		public static bool operator>=(Self lhs, Self rhs) => lhs.Length >= rhs.Length;
		public static bool operator>=(Self lhs, float rhs) => lhs.Length >= rhs;
		public static bool operator>=(float lhs, Self rhs) => lhs >= rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, float rhs) => lhs.Length < rhs;
		public static bool operator<(float lhs, Self rhs) => lhs < rhs.Length;
		public static bool operator<=(Self lhs, Self rhs) => lhs.Length <= rhs.Length;
		public static bool operator<=(Self lhs, float rhs) => lhs.Length <= rhs;
		public static bool operator<=(float lhs, Self rhs) => lhs <= rhs.Length;
	}
}