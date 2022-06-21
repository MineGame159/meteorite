using System;

namespace Meteorite {
	[CRepr]
	struct Color : this(uint8 r, uint8 g, uint8 b, uint8 a) {
		public float R => r / 255f;
		public float G => g / 255f;
		public float B => b / 255f;
		public float A => a / 255f;

		public this(uint8 r, uint8 g, uint8 b) : this(r, g, b, 255) {}
		public this(float r, float g, float b, float a) : this((.) (r * 255), (.) (g * 255), (.) (b * 255), (.) (a * 255)) {}
		public this(float r, float g, float b) : this(r, g, b, 1) {}
		public this(int32 v) : this((uint8) ((v >> 16) & 0x000000FF), (uint8) ((v >> 8) & 0x000000FF), (uint8) ((v) & 0x000000FF), (uint8) ((v >> 24) & 0x000000FF)) {}
		
		[Inline]
		public Color MulWithoutA(float f) => .((.) (r * f), (.) (g * f), (.) (b * f), a);

		[Inline]
		public Vec3f ToVec3f() => .(R, G, B);

		public override void ToString(String str) => str.AppendF("[{}, {}, {}, {}]", r, g, b, a);

		public const Color ZERO = .(0, 0, 0, 0);
		public const Color BLACK = .(0, 0, 0);
		public const Color WHITE = .(255, 255, 255);
	}
}