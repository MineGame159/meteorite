using System;

namespace Cacti {
	typealias Vec4f = Vec4<float>;
	typealias Vec4d = Vec4<double>;
	typealias Vec4i = Vec4<int>;
	
	struct Vec4<T> : IEquatable, IEquatable<Self>, IHashable where T : var, operator T + T, operator T * T, operator T / T, operator T % T, IHashable {
		public static Self ZERO = .();

		public T x, y, z, w;

		public this(T x, T y, T z, T w) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public this(Vec3<T> v, T w = 0) : this(v.x, v.y, v.z, w) {}
		public this(Vec2<T> v, T z = 0, float w = 0) : this(v.x, v.y, z, w) {}
		public this() : this(0, 0, 0, 0) {}

		public T this[int index] {
			get {
				switch (index) {
				case 1: return y;
				case 2: return z;
				case 3: return w;
				default: return x;
				}
			}
			set mut {
				switch (index) {
				case 1: y = value;
				case 2: z = value;
				case 3: w = value;
				default: x = value;
				}
			}
		}

		public double Length => Math.Sqrt(x * x + y * y + z * z + w * w);
		public double LengthSquared => x * x + y * y + z * z + w * w;

		public Self Normalize() {
			double l = Length;
			return .((.) (x / l), (.) (y / l), (.) (z / l), (.) (w / l));
		}

		public float Dot(Self v) => x * v.x + y * v.y + z * v.z + w * v.w;

		public Self Clamp(T min, T max) => .(Math.Clamp(x, min, max), Math.Clamp(y, min, max), Math.Clamp(z, min, max), Math.Clamp(w, min, max));
		public Self Lerp(T delta, Self end) => .(Utils.Lerp(delta, x, end.x), Utils.Lerp(delta, y, end.y), Utils.Lerp(delta, z, end.z), Utils.Lerp(delta, w, end.z));

		public bool Equals(Object o) => (o is Self) ? Equals((Self) o) : false;
		public bool Equals(Self v) => x == v.x && y == v.y && z == v.z && w == v.w;

		public int GetHashCode() {
			int hash = Utils.CombineHashCode(x.GetHashCode(), y.GetHashCode());
			hash = Utils.CombineHashCode(hash, z.GetHashCode());
			return Utils.CombineHashCode(hash, w.GetHashCode());
		}

		public override void ToString(String str) => str.AppendF("[{:0.00}, {:0.00}, {:0.00}, {:0.00}]", x, y, z, w);

		public static Self operator+(Self lhs, Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
		public static Self operator-(Self lhs, Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
		public static Self operator*(Self lhs, Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
		public static Self operator/(Self lhs, Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z, lhs.w / rhs.w);
		public static Self operator%(Self lhs, Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z, lhs.w % rhs.w);

		[Commutable]
		public static Self operator+(Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs, lhs.w + rhs);
		public static Self operator-(Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs, lhs.w - rhs);
		public static Self operator-(T lhs, Self rhs) => .(lhs - rhs.x, lhs - rhs.y, lhs - rhs.z, lhs - rhs.w);
		[Commutable]
		public static Self operator*(Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
		public static Self operator/(Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
		public static Self operator/(T lhs, Self rhs) => .(lhs / rhs.x, lhs / rhs.y, lhs / rhs.z, lhs / rhs.w);
		public static Self operator%(Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs, lhs.w % rhs);
		public static Self operator%(T lhs, Self rhs) => .(lhs % rhs.x, lhs % rhs.y, lhs % rhs.z, lhs % rhs.w);

		//public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y, -rhs.z, -rhs.w);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, T rhs) => lhs.Length > rhs;
		public static bool operator>(T lhs, Self rhs) => lhs > rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, T rhs) => lhs.Length < rhs;
		public static bool operator<(T lhs, Self rhs) => lhs < rhs.Length;
	}
}