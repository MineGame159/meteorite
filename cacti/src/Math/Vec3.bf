using System;

namespace Cacti;

typealias Vec3f = Vec3<float>;
typealias Vec3d = Vec3<double>;
typealias Vec3i = Vec3<int>;

//[VecBase(3)]
//[VecSwizzle(3)]
[CRepr]
struct Vec3<T> : IEquatable<Self>, IEquatable, IHashable where T : var {
	// Constants

	public const Self ZERO = .(0);
	public const Self ONE = .(1);
	public const Self NEG_ONE = .((.) -1);

	// Fields

	public T x, y, z;

	// Constructors

	public this(Vec2<T> xy, T z) {
		this.x = xy.x;
		this.y = xy.y;
		this.z = z;
	}

	public this(T x, T y, T z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public this(T value) {
		this.x = value;
		this.y = value;
		this.z = value;
	}

	public this() {
		this.x = 0;
		this.y = 0;
		this.z = 0;
	}

	// Indexer

	public T this[int index] {
		get {
			switch (index) {
			case 0: return x;
			case 1: return y;
			case 2: return z;
			default: Runtime.FatalError();
			}
		}
		set mut {
			switch (index) {
			case 0: x = value;
			case 1: y = value;
			case 2: z = value;
			default: Runtime.FatalError();
			}
		}
	}

	// Basic properties

	public bool IsZero => x == 0 && y == 0 && z == 0;

	public double LengthSquared => x * x + y * y + z * z;

	public double Length => Math.Sqrt(LengthSquared);

	// Basic methods

	public Self Normalize() {
		double l = Length;
		return .((.) (x / l), (.) (y / l), (.) (z / l));
	}

	public double Dot(Self vec) => x * vec.x + y * vec.y + z * vec.z;
	public Self Cross(Self vec) => .(y * vec.z - vec.y * z, z * vec.x - vec.z * x, x * vec.y - vec.x * y);

	public Self Min(Self vec) => .(Math.Min(x, vec.x), Math.Min(y, vec.y), Math.Min(z, vec.z));
	public Self Max(Self vec) => .(Math.Max(x, vec.x), Math.Max(y, vec.y), Math.Max(z, vec.z));

	public Self Clamp(T min, T max) => .(Math.Clamp(x, min, max), Math.Clamp(y, min, max), Math.Clamp(z, min, max));

	public Self Lerp(double delta, Self end) => .(Utils.Lerp(delta, x, end.x), Utils.Lerp(delta, y, end.y), Utils.Lerp(delta, z, end.z));

	// Equals

	public bool Equals(Self vec) => x == vec.x && y == vec.y && z == vec.z;
	public bool Equals(Object other) => (other is Self) ? Equals((Self) other) : false;

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);

	// Hash code

	public int GetHashCode() {
		int hash = 0;
		Utils.CombineHashCode(ref hash, x);
		Utils.CombineHashCode(ref hash, y);
		Utils.CombineHashCode(ref hash, z);
		return hash;
	}

	// To string

	public override void ToString(String str) => str.AppendF("[{:0.00}, {:0.00}, {:0.00}]", x, y, z);

	// Math operators

	public static Self operator+(Self lhs, Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
	[Commutable]
	public static Self operator+(Self lhs, T rhs) where T : INumeric => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs);
	public static Self operator-(Self lhs, Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);
	[Commutable]
	public static Self operator-(Self lhs, T rhs) where T : INumeric => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs);
	public static Self operator*(Self lhs, Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);
	[Commutable]
	public static Self operator*(Self lhs, T rhs) where T : INumeric => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs);
	public static Self operator/(Self lhs, Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z);
	[Commutable]
	public static Self operator/(Self lhs, T rhs) where T : INumeric => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs);
	public static Self operator%(Self lhs, Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z);
	[Commutable]
	public static Self operator%(Self lhs, T rhs) where T : INumeric => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs);

	// Comparison operators

	public static bool operator>(Self lhs, Self rhs) => lhs.LengthSquared > rhs.LengthSquared;
	[Commutable]
	public static bool operator>(Self lhs, T rhs) where T : INumeric => lhs.LengthSquared > rhs;
	public static bool operator<(Self lhs, Self rhs) => lhs.LengthSquared < rhs.LengthSquared;
	[Commutable]
	public static bool operator<(Self lhs, T rhs) where T : INumeric => lhs.LengthSquared < rhs;

#region Swizzling
	[NoShow] public Vec2<T> XX => .(x, x);
	[NoShow] public Vec2<T> YX => .(y, x);
	[NoShow] public Vec2<T> ZX => .(z, x);
	[NoShow] public Vec2<T> XY => .(x, y);
	[NoShow] public Vec2<T> YY => .(y, y);
	[NoShow] public Vec2<T> ZY => .(z, y);
	[NoShow] public Vec2<T> XZ => .(x, z);
	[NoShow] public Vec2<T> YZ => .(y, z);
	[NoShow] public Vec2<T> ZZ => .(z, z);
	[NoShow] public Vec3<T> XXY => .(x, x, y);
	[NoShow] public Vec3<T> YXY => .(y, x, y);
	[NoShow] public Vec3<T> ZXY => .(z, x, y);
	[NoShow] public Vec3<T> XYY => .(x, y, y);
	[NoShow] public Vec3<T> YYY => .(y, y, y);
	[NoShow] public Vec3<T> ZYY => .(z, y, y);
	[NoShow] public Vec3<T> XZY => .(x, z, y);
	[NoShow] public Vec3<T> YZY => .(y, z, y);
	[NoShow] public Vec3<T> ZZY => .(z, z, y);
	[NoShow] public Vec3<T> XXZ => .(x, x, z);
	[NoShow] public Vec3<T> YXZ => .(y, x, z);
	[NoShow] public Vec3<T> ZXZ => .(z, x, z);
	[NoShow] public Vec3<T> XYZ => .(x, y, z);
	[NoShow] public Vec3<T> YYZ => .(y, y, z);
	[NoShow] public Vec3<T> ZYZ => .(z, y, z);
	[NoShow] public Vec3<T> XZZ => .(x, z, z);
	[NoShow] public Vec3<T> YZZ => .(y, z, z);
	[NoShow] public Vec3<T> ZZZ => .(z, z, z);
#endregion
}

extension Vec3<T> where T : operator -T {
	public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y, -rhs.z);
}

#region Conversions

// To float

extension Vec3<T> where T : operator implicit Float {
	public static implicit operator Vec3f(Self vec) => .(vec.x, vec.y, vec.z);
}

extension Vec3<T> where T : operator explicit Float {
	public static explicit operator Vec3f(Self vec) => .((.) vec.x, (.) vec.y, (.) vec.z);
}

// To double

extension Vec3<T> where T : operator implicit Double {
	public static implicit operator Vec3d(Self vec) => .(vec.x, vec.y, vec.z);
}

extension Vec3<T> where T : operator explicit Double {
	public static explicit operator Vec3d(Self vec) => .((.) vec.x, (.) vec.y, (.) vec.z);
}

// To int

extension Vec3<T> where T : operator implicit Int {
	public static implicit operator Vec3i(Self vec) => .(vec.x, vec.y, vec.z);
}

extension Vec3<T> where T : operator explicit Int {
	public static explicit operator Vec3i(Self vec) => .((.) vec.x, (.) vec.y, (.) vec.z);
}

#endregion