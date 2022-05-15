using System;
using System.Collections;

namespace Meteorite {
	enum QuadCullFace {
		None,
		Top,
		Bottom,
		East, // Východ
		West, // Západ
		North, // Sever
		South // Juh
	}

	class Quad {
		public Direction direction;
		public Vec3f[4] vertices;
		public QuadCullFace cullFace;
		public float light;
		public TextureRegion region;
		public bool tint;

		public this(Direction direction, Vec3f[4] vertices, QuadCullFace cullFace, float light, bool tint) {
			this.direction = direction;
			this.vertices = vertices;
			this.cullFace = cullFace;
			this.light = light;
			this.tint = tint;
		}
	}

	class Model {
		public List<Quad> quads = new .() ~ DeleteContainerAndItems!(_);
	}
}