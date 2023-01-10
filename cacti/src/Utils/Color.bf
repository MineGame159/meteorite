using System;

namespace Cacti {
	[CRepr]
	struct Color : IEquatable, IEquatable<Self>, IHashable {
		public uint8 r, g, b, a;

		public this(uint8 r, uint8 g, uint8 b, uint8 a) {
			this.r = r;
			this.g = g;
			this.b = b;
			this.a = a;
		}

		public this(uint8 r, uint8 g, uint8 b) : this(r, g, b, 255) {}
		public this(float r, float g, float b, float a) : this((.) (r * 255), (.) (g * 255), (.) (b * 255), (.) (a * 255)) {}
		public this(float r, float g, float b) : this(r, g, b, 1) {}
		public this(int32 v) : this((uint8) ((v >> 16) & 0x000000FF), (uint8) ((v >> 8) & 0x000000FF), (uint8) ((v) & 0x000000FF), (uint8) ((v >> 24) & 0x000000FF)) {}

		public float R => r / 255f;
		public float G => g / 255f;
		public float B => b / 255f;
		public float A => a / 255f;

		public Vec3f ToVec3f => .(R, G, B);
		public Vec4f ToVec4f => .(R, G, B, A);

		public Color MulWithoutA(float f) => .((.) (r * f), (.) (g * f), (.) (b * f), a);

		public bool Equals(Object o) => (o is Self) ? Equals((Self) o) : false;
		public bool Equals(Self v) => r == v.r && g == v.g && b == v.b && a == v.a;

		public int GetHashCode() {
			int hash = Utils.CombineHashCode(r.GetHashCode(), g.GetHashCode());
			hash = Utils.CombineHashCode(hash, b.GetHashCode());
			return Utils.CombineHashCode(hash, a.GetHashCode());
		}

		public override void ToString(String str) => str.AppendF("[{}, {}, {}, {}]", r, g, b, a);

		public const Color ZERO = .(0, 0, 0, 0);
		public const Color BLACK = .(0, 0, 0);
		public const Color WHITE = .(255, 255, 255);
	}
}