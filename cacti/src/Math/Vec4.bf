using System;

namespace Cacti;

typealias Vec4f = Vec4<float>;
typealias Vec4d = Vec4<double>;
typealias Vec4i = Vec4<int>;

//[VecBase(4)]
//[VecSwizzle(4)]
[CRepr]
struct Vec4<T> : IEquatable<Self>, IEquatable, IHashable where T : var {
	// Constants

	public const Self ZERO = .(0);
	public const Self ONE = .(1);

	// Fields

	public T x, y, z, w;

	// Constructors

	public this(Vec3<T> xyz, T w) {
		this.x = xyz.x;
		this.y = xyz.y;
		this.z = xyz.z;
		this.w = w;
	}

	public this(T x, T y, T z, T w) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public this(T value) {
		this.x = value;
		this.y = value;
		this.z = value;
		this.w = value;
	}

	public this() {
		this.x = 0;
		this.y = 0;
		this.z = 0;
		this.w = 0;
	}

	// Indexer

	public T this[int index] {
		get {
			switch (index) {
			case 0: return x;
			case 1: return y;
			case 2: return z;
			case 3: return w;
			default: Runtime.FatalError();
			}
		}
		set mut {
			switch (index) {
			case 0: x = value;
			case 1: y = value;
			case 2: z = value;
			case 3: w = value;
			default: Runtime.FatalError();
			}
		}
	}

	// Basic properties

	public bool IsZero => x == 0 && y == 0 && z == 0 && w == 0;

	public double LengthSquared => x * x + y * y + z * z + w * w;

	public double Length => Math.Sqrt(LengthSquared);

	// Basic methods

	public Self Normalize() {
		double l = Length;
		return .((.) (x / l), (.) (y / l), (.) (z / l), (.) (w / l));
	}

	public double Dot(Self vec) => x * vec.x + y * vec.y + z * vec.z + w * vec.w;

	public Self Min(Self vec) => .(Math.Min(x, vec.x), Math.Min(y, vec.y), Math.Min(z, vec.z), Math.Min(w, vec.w));
	public Self Max(Self vec) => .(Math.Max(x, vec.x), Math.Max(y, vec.y), Math.Max(z, vec.z), Math.Max(w, vec.w));

	public Self Clamp(T min, T max) => .(Math.Clamp(x, min, max), Math.Clamp(y, min, max), Math.Clamp(z, min, max), Math.Clamp(w, min, max));

	public Self Lerp(double delta, Self end) => .(Utils.Lerp(delta, x, end.x), Utils.Lerp(delta, y, end.y), Utils.Lerp(delta, z, end.z), Utils.Lerp(delta, w, end.w));

	// Equals

	public bool Equals(Self vec) => x == vec.x && y == vec.y && z == vec.z && w == vec.w;
	public bool Equals(Object other) => (other is Self) ? Equals((Self) other) : false;

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);

	// Hash code

	public int GetHashCode() {
		int hash = 0;
		Utils.CombineHashCode(ref hash, x);
		Utils.CombineHashCode(ref hash, y);
		Utils.CombineHashCode(ref hash, z);
		Utils.CombineHashCode(ref hash, w);
		return hash;
	}

	// To string

	public override void ToString(String str) => str.AppendF("[{:0.00}, {:0.00}, {:0.00}, {:0.00}]", x, y, z, w);

	// Math operators

	public static Self operator+(Self lhs, Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
	[Commutable]
	public static Self operator+(Self lhs, T rhs) where T : INumeric => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs, lhs.w + rhs);
	public static Self operator-(Self lhs, Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
	[Commutable]
	public static Self operator-(Self lhs, T rhs) where T : INumeric => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs, lhs.w - rhs);
	public static Self operator*(Self lhs, Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
	[Commutable]
	public static Self operator*(Self lhs, T rhs) where T : INumeric => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
	public static Self operator/(Self lhs, Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z, lhs.w / rhs.w);
	[Commutable]
	public static Self operator/(Self lhs, T rhs) where T : INumeric => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
	public static Self operator%(Self lhs, Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z, lhs.w % rhs.w);
	[Commutable]
	public static Self operator%(Self lhs, T rhs) where T : INumeric => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs, lhs.w % rhs);

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
	[NoShow] public Vec2<T> WX => .(w, x);
	[NoShow] public Vec2<T> XY => .(x, y);
	[NoShow] public Vec2<T> YY => .(y, y);
	[NoShow] public Vec2<T> ZY => .(z, y);
	[NoShow] public Vec2<T> WY => .(w, y);
	[NoShow] public Vec2<T> XZ => .(x, z);
	[NoShow] public Vec2<T> YZ => .(y, z);
	[NoShow] public Vec2<T> ZZ => .(z, z);
	[NoShow] public Vec2<T> WZ => .(w, z);
	[NoShow] public Vec2<T> XW => .(x, w);
	[NoShow] public Vec2<T> YW => .(y, w);
	[NoShow] public Vec2<T> ZW => .(z, w);
	[NoShow] public Vec2<T> WW => .(w, w);
	[NoShow] public Vec3<T> XXY => .(x, x, y);
	[NoShow] public Vec3<T> YXY => .(y, x, y);
	[NoShow] public Vec3<T> ZXY => .(z, x, y);
	[NoShow] public Vec3<T> WXY => .(w, x, y);
	[NoShow] public Vec3<T> XYY => .(x, y, y);
	[NoShow] public Vec3<T> YYY => .(y, y, y);
	[NoShow] public Vec3<T> ZYY => .(z, y, y);
	[NoShow] public Vec3<T> WYY => .(w, y, y);
	[NoShow] public Vec3<T> XZY => .(x, z, y);
	[NoShow] public Vec3<T> YZY => .(y, z, y);
	[NoShow] public Vec3<T> ZZY => .(z, z, y);
	[NoShow] public Vec3<T> WZY => .(w, z, y);
	[NoShow] public Vec3<T> XWY => .(x, w, y);
	[NoShow] public Vec3<T> YWY => .(y, w, y);
	[NoShow] public Vec3<T> ZWY => .(z, w, y);
	[NoShow] public Vec3<T> WWY => .(w, w, y);
	[NoShow] public Vec3<T> XXZ => .(x, x, z);
	[NoShow] public Vec3<T> YXZ => .(y, x, z);
	[NoShow] public Vec3<T> ZXZ => .(z, x, z);
	[NoShow] public Vec3<T> WXZ => .(w, x, z);
	[NoShow] public Vec3<T> XYZ => .(x, y, z);
	[NoShow] public Vec3<T> YYZ => .(y, y, z);
	[NoShow] public Vec3<T> ZYZ => .(z, y, z);
	[NoShow] public Vec3<T> WYZ => .(w, y, z);
	[NoShow] public Vec3<T> XZZ => .(x, z, z);
	[NoShow] public Vec3<T> YZZ => .(y, z, z);
	[NoShow] public Vec3<T> ZZZ => .(z, z, z);
	[NoShow] public Vec3<T> WZZ => .(w, z, z);
	[NoShow] public Vec3<T> XWZ => .(x, w, z);
	[NoShow] public Vec3<T> YWZ => .(y, w, z);
	[NoShow] public Vec3<T> ZWZ => .(z, w, z);
	[NoShow] public Vec3<T> WWZ => .(w, w, z);
	[NoShow] public Vec3<T> XXW => .(x, x, w);
	[NoShow] public Vec3<T> YXW => .(y, x, w);
	[NoShow] public Vec3<T> ZXW => .(z, x, w);
	[NoShow] public Vec3<T> WXW => .(w, x, w);
	[NoShow] public Vec3<T> XYW => .(x, y, w);
	[NoShow] public Vec3<T> YYW => .(y, y, w);
	[NoShow] public Vec3<T> ZYW => .(z, y, w);
	[NoShow] public Vec3<T> WYW => .(w, y, w);
	[NoShow] public Vec3<T> XZW => .(x, z, w);
	[NoShow] public Vec3<T> YZW => .(y, z, w);
	[NoShow] public Vec3<T> ZZW => .(z, z, w);
	[NoShow] public Vec3<T> WZW => .(w, z, w);
	[NoShow] public Vec3<T> XWW => .(x, w, w);
	[NoShow] public Vec3<T> YWW => .(y, w, w);
	[NoShow] public Vec3<T> ZWW => .(z, w, w);
	[NoShow] public Vec3<T> WWW => .(w, w, w);
	[NoShow] public Vec4<T> XXXY => .(x, x, x, y);
	[NoShow] public Vec4<T> YXXY => .(y, x, x, y);
	[NoShow] public Vec4<T> ZXXY => .(z, x, x, y);
	[NoShow] public Vec4<T> WXXY => .(w, x, x, y);
	[NoShow] public Vec4<T> XYXY => .(x, y, x, y);
	[NoShow] public Vec4<T> YYXY => .(y, y, x, y);
	[NoShow] public Vec4<T> ZYXY => .(z, y, x, y);
	[NoShow] public Vec4<T> WYXY => .(w, y, x, y);
	[NoShow] public Vec4<T> XZXY => .(x, z, x, y);
	[NoShow] public Vec4<T> YZXY => .(y, z, x, y);
	[NoShow] public Vec4<T> ZZXY => .(z, z, x, y);
	[NoShow] public Vec4<T> WZXY => .(w, z, x, y);
	[NoShow] public Vec4<T> XWXY => .(x, w, x, y);
	[NoShow] public Vec4<T> YWXY => .(y, w, x, y);
	[NoShow] public Vec4<T> ZWXY => .(z, w, x, y);
	[NoShow] public Vec4<T> WWXY => .(w, w, x, y);
	[NoShow] public Vec4<T> XXYY => .(x, x, y, y);
	[NoShow] public Vec4<T> YXYY => .(y, x, y, y);
	[NoShow] public Vec4<T> ZXYY => .(z, x, y, y);
	[NoShow] public Vec4<T> WXYY => .(w, x, y, y);
	[NoShow] public Vec4<T> XYYY => .(x, y, y, y);
	[NoShow] public Vec4<T> YYYY => .(y, y, y, y);
	[NoShow] public Vec4<T> ZYYY => .(z, y, y, y);
	[NoShow] public Vec4<T> WYYY => .(w, y, y, y);
	[NoShow] public Vec4<T> XZYY => .(x, z, y, y);
	[NoShow] public Vec4<T> YZYY => .(y, z, y, y);
	[NoShow] public Vec4<T> ZZYY => .(z, z, y, y);
	[NoShow] public Vec4<T> WZYY => .(w, z, y, y);
	[NoShow] public Vec4<T> XWYY => .(x, w, y, y);
	[NoShow] public Vec4<T> YWYY => .(y, w, y, y);
	[NoShow] public Vec4<T> ZWYY => .(z, w, y, y);
	[NoShow] public Vec4<T> WWYY => .(w, w, y, y);
	[NoShow] public Vec4<T> XXZY => .(x, x, z, y);
	[NoShow] public Vec4<T> YXZY => .(y, x, z, y);
	[NoShow] public Vec4<T> ZXZY => .(z, x, z, y);
	[NoShow] public Vec4<T> WXZY => .(w, x, z, y);
	[NoShow] public Vec4<T> XYZY => .(x, y, z, y);
	[NoShow] public Vec4<T> YYZY => .(y, y, z, y);
	[NoShow] public Vec4<T> ZYZY => .(z, y, z, y);
	[NoShow] public Vec4<T> WYZY => .(w, y, z, y);
	[NoShow] public Vec4<T> XZZY => .(x, z, z, y);
	[NoShow] public Vec4<T> YZZY => .(y, z, z, y);
	[NoShow] public Vec4<T> ZZZY => .(z, z, z, y);
	[NoShow] public Vec4<T> WZZY => .(w, z, z, y);
	[NoShow] public Vec4<T> XWZY => .(x, w, z, y);
	[NoShow] public Vec4<T> YWZY => .(y, w, z, y);
	[NoShow] public Vec4<T> ZWZY => .(z, w, z, y);
	[NoShow] public Vec4<T> WWZY => .(w, w, z, y);
	[NoShow] public Vec4<T> XXWY => .(x, x, w, y);
	[NoShow] public Vec4<T> YXWY => .(y, x, w, y);
	[NoShow] public Vec4<T> ZXWY => .(z, x, w, y);
	[NoShow] public Vec4<T> WXWY => .(w, x, w, y);
	[NoShow] public Vec4<T> XYWY => .(x, y, w, y);
	[NoShow] public Vec4<T> YYWY => .(y, y, w, y);
	[NoShow] public Vec4<T> ZYWY => .(z, y, w, y);
	[NoShow] public Vec4<T> WYWY => .(w, y, w, y);
	[NoShow] public Vec4<T> XZWY => .(x, z, w, y);
	[NoShow] public Vec4<T> YZWY => .(y, z, w, y);
	[NoShow] public Vec4<T> ZZWY => .(z, z, w, y);
	[NoShow] public Vec4<T> WZWY => .(w, z, w, y);
	[NoShow] public Vec4<T> XWWY => .(x, w, w, y);
	[NoShow] public Vec4<T> YWWY => .(y, w, w, y);
	[NoShow] public Vec4<T> ZWWY => .(z, w, w, y);
	[NoShow] public Vec4<T> WWWY => .(w, w, w, y);
	[NoShow] public Vec4<T> XXXZ => .(x, x, x, z);
	[NoShow] public Vec4<T> YXXZ => .(y, x, x, z);
	[NoShow] public Vec4<T> ZXXZ => .(z, x, x, z);
	[NoShow] public Vec4<T> WXXZ => .(w, x, x, z);
	[NoShow] public Vec4<T> XYXZ => .(x, y, x, z);
	[NoShow] public Vec4<T> YYXZ => .(y, y, x, z);
	[NoShow] public Vec4<T> ZYXZ => .(z, y, x, z);
	[NoShow] public Vec4<T> WYXZ => .(w, y, x, z);
	[NoShow] public Vec4<T> XZXZ => .(x, z, x, z);
	[NoShow] public Vec4<T> YZXZ => .(y, z, x, z);
	[NoShow] public Vec4<T> ZZXZ => .(z, z, x, z);
	[NoShow] public Vec4<T> WZXZ => .(w, z, x, z);
	[NoShow] public Vec4<T> XWXZ => .(x, w, x, z);
	[NoShow] public Vec4<T> YWXZ => .(y, w, x, z);
	[NoShow] public Vec4<T> ZWXZ => .(z, w, x, z);
	[NoShow] public Vec4<T> WWXZ => .(w, w, x, z);
	[NoShow] public Vec4<T> XXYZ => .(x, x, y, z);
	[NoShow] public Vec4<T> YXYZ => .(y, x, y, z);
	[NoShow] public Vec4<T> ZXYZ => .(z, x, y, z);
	[NoShow] public Vec4<T> WXYZ => .(w, x, y, z);
	[NoShow] public Vec4<T> XYYZ => .(x, y, y, z);
	[NoShow] public Vec4<T> YYYZ => .(y, y, y, z);
	[NoShow] public Vec4<T> ZYYZ => .(z, y, y, z);
	[NoShow] public Vec4<T> WYYZ => .(w, y, y, z);
	[NoShow] public Vec4<T> XZYZ => .(x, z, y, z);
	[NoShow] public Vec4<T> YZYZ => .(y, z, y, z);
	[NoShow] public Vec4<T> ZZYZ => .(z, z, y, z);
	[NoShow] public Vec4<T> WZYZ => .(w, z, y, z);
	[NoShow] public Vec4<T> XWYZ => .(x, w, y, z);
	[NoShow] public Vec4<T> YWYZ => .(y, w, y, z);
	[NoShow] public Vec4<T> ZWYZ => .(z, w, y, z);
	[NoShow] public Vec4<T> WWYZ => .(w, w, y, z);
	[NoShow] public Vec4<T> XXZZ => .(x, x, z, z);
	[NoShow] public Vec4<T> YXZZ => .(y, x, z, z);
	[NoShow] public Vec4<T> ZXZZ => .(z, x, z, z);
	[NoShow] public Vec4<T> WXZZ => .(w, x, z, z);
	[NoShow] public Vec4<T> XYZZ => .(x, y, z, z);
	[NoShow] public Vec4<T> YYZZ => .(y, y, z, z);
	[NoShow] public Vec4<T> ZYZZ => .(z, y, z, z);
	[NoShow] public Vec4<T> WYZZ => .(w, y, z, z);
	[NoShow] public Vec4<T> XZZZ => .(x, z, z, z);
	[NoShow] public Vec4<T> YZZZ => .(y, z, z, z);
	[NoShow] public Vec4<T> ZZZZ => .(z, z, z, z);
	[NoShow] public Vec4<T> WZZZ => .(w, z, z, z);
	[NoShow] public Vec4<T> XWZZ => .(x, w, z, z);
	[NoShow] public Vec4<T> YWZZ => .(y, w, z, z);
	[NoShow] public Vec4<T> ZWZZ => .(z, w, z, z);
	[NoShow] public Vec4<T> WWZZ => .(w, w, z, z);
	[NoShow] public Vec4<T> XXWZ => .(x, x, w, z);
	[NoShow] public Vec4<T> YXWZ => .(y, x, w, z);
	[NoShow] public Vec4<T> ZXWZ => .(z, x, w, z);
	[NoShow] public Vec4<T> WXWZ => .(w, x, w, z);
	[NoShow] public Vec4<T> XYWZ => .(x, y, w, z);
	[NoShow] public Vec4<T> YYWZ => .(y, y, w, z);
	[NoShow] public Vec4<T> ZYWZ => .(z, y, w, z);
	[NoShow] public Vec4<T> WYWZ => .(w, y, w, z);
	[NoShow] public Vec4<T> XZWZ => .(x, z, w, z);
	[NoShow] public Vec4<T> YZWZ => .(y, z, w, z);
	[NoShow] public Vec4<T> ZZWZ => .(z, z, w, z);
	[NoShow] public Vec4<T> WZWZ => .(w, z, w, z);
	[NoShow] public Vec4<T> XWWZ => .(x, w, w, z);
	[NoShow] public Vec4<T> YWWZ => .(y, w, w, z);
	[NoShow] public Vec4<T> ZWWZ => .(z, w, w, z);
	[NoShow] public Vec4<T> WWWZ => .(w, w, w, z);
	[NoShow] public Vec4<T> XXXW => .(x, x, x, w);
	[NoShow] public Vec4<T> YXXW => .(y, x, x, w);
	[NoShow] public Vec4<T> ZXXW => .(z, x, x, w);
	[NoShow] public Vec4<T> WXXW => .(w, x, x, w);
	[NoShow] public Vec4<T> XYXW => .(x, y, x, w);
	[NoShow] public Vec4<T> YYXW => .(y, y, x, w);
	[NoShow] public Vec4<T> ZYXW => .(z, y, x, w);
	[NoShow] public Vec4<T> WYXW => .(w, y, x, w);
	[NoShow] public Vec4<T> XZXW => .(x, z, x, w);
	[NoShow] public Vec4<T> YZXW => .(y, z, x, w);
	[NoShow] public Vec4<T> ZZXW => .(z, z, x, w);
	[NoShow] public Vec4<T> WZXW => .(w, z, x, w);
	[NoShow] public Vec4<T> XWXW => .(x, w, x, w);
	[NoShow] public Vec4<T> YWXW => .(y, w, x, w);
	[NoShow] public Vec4<T> ZWXW => .(z, w, x, w);
	[NoShow] public Vec4<T> WWXW => .(w, w, x, w);
	[NoShow] public Vec4<T> XXYW => .(x, x, y, w);
	[NoShow] public Vec4<T> YXYW => .(y, x, y, w);
	[NoShow] public Vec4<T> ZXYW => .(z, x, y, w);
	[NoShow] public Vec4<T> WXYW => .(w, x, y, w);
	[NoShow] public Vec4<T> XYYW => .(x, y, y, w);
	[NoShow] public Vec4<T> YYYW => .(y, y, y, w);
	[NoShow] public Vec4<T> ZYYW => .(z, y, y, w);
	[NoShow] public Vec4<T> WYYW => .(w, y, y, w);
	[NoShow] public Vec4<T> XZYW => .(x, z, y, w);
	[NoShow] public Vec4<T> YZYW => .(y, z, y, w);
	[NoShow] public Vec4<T> ZZYW => .(z, z, y, w);
	[NoShow] public Vec4<T> WZYW => .(w, z, y, w);
	[NoShow] public Vec4<T> XWYW => .(x, w, y, w);
	[NoShow] public Vec4<T> YWYW => .(y, w, y, w);
	[NoShow] public Vec4<T> ZWYW => .(z, w, y, w);
	[NoShow] public Vec4<T> WWYW => .(w, w, y, w);
	[NoShow] public Vec4<T> XXZW => .(x, x, z, w);
	[NoShow] public Vec4<T> YXZW => .(y, x, z, w);
	[NoShow] public Vec4<T> ZXZW => .(z, x, z, w);
	[NoShow] public Vec4<T> WXZW => .(w, x, z, w);
	[NoShow] public Vec4<T> XYZW => .(x, y, z, w);
	[NoShow] public Vec4<T> YYZW => .(y, y, z, w);
	[NoShow] public Vec4<T> ZYZW => .(z, y, z, w);
	[NoShow] public Vec4<T> WYZW => .(w, y, z, w);
	[NoShow] public Vec4<T> XZZW => .(x, z, z, w);
	[NoShow] public Vec4<T> YZZW => .(y, z, z, w);
	[NoShow] public Vec4<T> ZZZW => .(z, z, z, w);
	[NoShow] public Vec4<T> WZZW => .(w, z, z, w);
	[NoShow] public Vec4<T> XWZW => .(x, w, z, w);
	[NoShow] public Vec4<T> YWZW => .(y, w, z, w);
	[NoShow] public Vec4<T> ZWZW => .(z, w, z, w);
	[NoShow] public Vec4<T> WWZW => .(w, w, z, w);
	[NoShow] public Vec4<T> XXWW => .(x, x, w, w);
	[NoShow] public Vec4<T> YXWW => .(y, x, w, w);
	[NoShow] public Vec4<T> ZXWW => .(z, x, w, w);
	[NoShow] public Vec4<T> WXWW => .(w, x, w, w);
	[NoShow] public Vec4<T> XYWW => .(x, y, w, w);
	[NoShow] public Vec4<T> YYWW => .(y, y, w, w);
	[NoShow] public Vec4<T> ZYWW => .(z, y, w, w);
	[NoShow] public Vec4<T> WYWW => .(w, y, w, w);
	[NoShow] public Vec4<T> XZWW => .(x, z, w, w);
	[NoShow] public Vec4<T> YZWW => .(y, z, w, w);
	[NoShow] public Vec4<T> ZZWW => .(z, z, w, w);
	[NoShow] public Vec4<T> WZWW => .(w, z, w, w);
	[NoShow] public Vec4<T> XWWW => .(x, w, w, w);
	[NoShow] public Vec4<T> YWWW => .(y, w, w, w);
	[NoShow] public Vec4<T> ZWWW => .(z, w, w, w);
	[NoShow] public Vec4<T> WWWW => .(w, w, w, w);
#endregion
}

extension Vec4<T> where T : operator -T {
	public static Self operator-(Self rhs) => .(-rhs.x, -rhs.y, -rhs.z, -rhs.w);
}

#region Conversions

// To float

extension Vec4<T> where T : operator implicit Float {
	public static implicit operator Vec4f(Self vec) => .(vec.x, vec.y, vec.z, vec.w);
}

extension Vec4<T> where T : operator explicit Float {
	public static explicit operator Vec4f(Self vec) => .((.) vec.x, (.) vec.y, (.) vec.z, (.) vec.w);
}

// To double

extension Vec4<T> where T : operator implicit Double {
	public static implicit operator Vec4d(Self vec) => .(vec.x, vec.y, vec.z, vec.w);
}

extension Vec4<T> where T : operator explicit Double {
	public static explicit operator Vec4d(Self vec) => .((.) vec.x, (.) vec.y, (.) vec.z, (.) vec.w);
}

// To int

extension Vec4<T> where T : operator implicit Int {
	public static implicit operator Vec4i(Self vec) => .(vec.x, vec.y, vec.z, vec.w);
}

extension Vec4<T> where T : operator explicit Int {
	public static explicit operator Vec4i(Self vec) => .((.) vec.x, (.) vec.y, (.) vec.z, (.) vec.w);
}

#endregion