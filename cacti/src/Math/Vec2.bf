using System;

namespace Cacti;

typealias Vec2f = Vec2<float>;
typealias Vec2d = Vec2<double>;
typealias Vec2i = Vec2<int>;

//[VecBase(2)]
//[VecSwizzle(2)]
[CRepr]
struct Vec2<T> : IEquatable<Self>, IEquatable, IHashable where T : var {
	// Constants

	public const Self ZERO = .(0);
	public const Self ONE = .(1);

	// Fields

	public T x, y;

	// Constructors

	public this(T x, T y) {
		this.x = x;
		this.y = y;
	}

	public this(T value) {
		this.x = value;
		this.y = value;
	}

	public this() {
		this.x = 0;
		this.y = 0;
	}

	// Indexer

	public T this[int index] {
		get {
			switch (index) {
			case 0: return x;
			case 1: return y;
			default: Runtime.FatalError();
			}
		}
		set mut {
			switch (index) {
			case 0: x = value;
			case 1: y = value;
			default: Runtime.FatalError();
			}
		}
	}

	// Basic properties

	public bool IsZero => x == 0 && y == 0;

	public double LengthSquared => x * x + y * y;

	public double Length => Math.Sqrt(LengthSquared);

	// Basic methods

	public Self Normalize() {
		double l = Length;
		return .((.) (x / l), (.) (y / l));
	}

	public double Dot(Self vec) => x * vec.x + y * vec.y;

	public Self Min(Self vec) => .(Math.Min(x, vec.x), Math.Min(y, vec.y));
	public Self Max(Self vec) => .(Math.Max(x, vec.x), Math.Max(y, vec.y));

	public Self Clamp(T min, T max) => .(Math.Clamp(x, min, max), Math.Clamp(y, min, max));

	public Self Lerp(double delta, Self end) => .(Utils.Lerp(delta, x, end.x), Utils.Lerp(delta, y, end.y));


	// Equals

	public bool Equals(Self vec) => x == vec.x && y == vec.y;
	public bool Equals(Object other) => (other is Self) ? Equals((Self) other) : false;

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);

	// Hash code

	public int GetHashCode() {
		int hash = 0;
		Utils.CombineHashCode(ref hash, x);
		Utils.CombineHashCode(ref hash, y);
		return hash;
	}

	// To string

	public override void ToString(String str) => str.AppendF("[{:0.00}, {:0.00}]", x, y);

	// Math operators

	public static Self operator+(Self lhs, Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y);
	[Commutable]
	public static Self operator+(Self lhs, T rhs) where T : INumeric => .(lhs.x + rhs, lhs.y + rhs);
	public static Self operator-(Self lhs, Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y);
	[Commutable]
	public static Self operator-(Self lhs, T rhs) where T : INumeric => .(lhs.x - rhs, lhs.y - rhs);
	public static Self operator*(Self lhs, Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y);
	[Commutable]
	public static Self operator*(Self lhs, T rhs) where T : INumeric => .(lhs.x * rhs, lhs.y * rhs);
	public static Self operator/(Self lhs, Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y);
	[Commutable]
	public static Self operator/(Self lhs, T rhs) where T : INumeric => .(lhs.x / rhs, lhs.y / rhs);
	public static Self operator%(Self lhs, Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y);
	[Commutable]
	public static Self operator%(Self lhs, T rhs) where T : INumeric => .(lhs.x % rhs, lhs.y % rhs);

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
	[NoShow] public Vec2<T> XY => .(x, y);
	[NoShow] public Vec2<T> YY => .(y, y);
#endregion
}

extension Vec2<T> where T : operator -T {
	public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y);
}

#region Conversions

// To float

extension Vec2<T> where T : operator implicit Float {
	public static implicit operator Vec2f(Self vec) => .(vec.x, vec.y);
}

extension Vec2<T> where T : operator explicit Float {
	public static explicit operator Vec2f(Self vec) => .((.) vec.x, (.) vec.y);
}

// To double

extension Vec2<T> where T : operator implicit Double {
	public static implicit operator Vec2d(Self vec) => .(vec.x, vec.y);
}

extension Vec2<T> where T : operator explicit Double {
	public static explicit operator Vec2d(Self vec) => .((.) vec.x, (.) vec.y);
}

// To int

extension Vec2<T> where T : operator implicit Int {
	public static implicit operator Vec2i(Self vec) => .(vec.x, vec.y);
}

extension Vec2<T> where T : operator explicit Int {
	public static explicit operator Vec2i(Self vec) => .((.) vec.x, (.) vec.y);
}

#endregion