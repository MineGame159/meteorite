using System;

namespace Meteorite {
	struct Vec4 : IEquatable, IEquatable<Vec4>, IHashable {
		public float x, y, z, w;

		public this(float x, float y, float z, float w) {
			this = ?;
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public this(Vec3f v, float w = 0) : this(v.x, v.y, v.z, w) {}
		public this() : this(0, 0, 0, 0) {}

		public float this[int index] {
			get {
				switch (index) {
				case 1: return y;
				case 2: return z;
				case 3: return w;
				default: return x;
				}
			}
		}

		public float Length => Math.Sqrt(x * x + y * y + z * z + w * w);

		public Self Normalize() {
			float l = Length;
			return .((.) (x / l), (.) (y / l), (.) (z / l), (.) (w / l));
		}

		public float Dot(Self v) => x * v.x + y * v.y + z * v.z + w * v.w;

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
		public static Self operator+(Self lhs, float rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs, lhs.w + rhs);
		public static Self operator-(Self lhs, float rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs, lhs.w - rhs);
		public static Self operator-(float lhs, Self rhs) => .(lhs - rhs.x, lhs - rhs.y, lhs - rhs.z, lhs - rhs.w);
		[Commutable]
		public static Self operator*(Self lhs, float rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
		public static Self operator/(Self lhs, float rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
		public static Self operator/(float lhs, Self rhs) => .(lhs / rhs.x, lhs / rhs.y, lhs / rhs.z, lhs / rhs.w);
		public static Self operator%(Self lhs, float rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs, lhs.w % rhs);
		public static Self operator%(float lhs, Self rhs) => .(lhs % rhs.x, lhs % rhs.y, lhs % rhs.z, lhs % rhs.w);

		public static bool operator>(Self lhs, Self rhs) => lhs.Length > rhs.Length;
		public static bool operator>(Self lhs, float rhs) => lhs.Length > rhs;
		public static bool operator>(float lhs, Self rhs) => lhs > rhs.Length;

		public static bool operator<(Self lhs, Self rhs) => lhs.Length < rhs.Length;
		public static bool operator<(Self lhs, float rhs) => lhs.Length < rhs;
		public static bool operator<(float lhs, Self rhs) => lhs < rhs.Length;
	}
}