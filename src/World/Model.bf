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
		public uint16 texture;
		public bool tint;
		public Vec3f min, max;
		public bool adjacent;

		public this(Direction direction, Vec3f[4] vertices, QuadCullFace cullFace, float light, bool tint) {
			this.direction = direction;
			this.vertices = vertices;
			this.cullFace = cullFace;
			this.light = light;
			this.tint = tint;

			// Calculate min and max
			min = .(1, 1, 1);

			for (Vec3f vertex in vertices) {
				min.x = Math.Min(min.x, vertex.x);
				min.y = Math.Min(min.y, vertex.y);
				min.z = Math.Min(min.z, vertex.z);

				max.x = Math.Max(max.x, vertex.x);
				max.y = Math.Max(max.y, vertex.y);
				max.z = Math.Max(max.z, vertex.z);
			}
		}
	}

	class Model {
		public List<Quad> quads = new .() ~ DeleteContainerAndItems!(_);
		public bool fullBlock;

		private List<Quad>[6] adjacentQuads ~ for (let quads in _) delete quads;

		public this() {
			for (int i < 6) {
				adjacentQuads[i] = new List<Quad>(1);
			}
		}

		public void Add(Quad quad) {
			quads.Add(quad);

			// Detect adjacent quads
			quad.adjacent = true;

			switch (quad.direction) {
			case .Up, .Down:
				int y = quad.direction == .Up ? 1 : 0;

				for (Vec3f vertex in quad.vertices) {
					if (vertex.y != y) {
						quad.adjacent = false;
						break;
					}
				}
			case .East, .West:
				int x = quad.direction == .East ? 1 : 0;

				for (Vec3f vertex in quad.vertices) {
					if (vertex.x != x) {
						quad.adjacent = false;
						break;
					}
				}
			case .North, .South:
				int z = quad.direction == .South ? 1 : 0;

				for (Vec3f vertex in quad.vertices) {
					if (vertex.z != z) {
						quad.adjacent = false;
						break;
					}
				}
			}

			if (quad.adjacent) GetAdjacentQuads(quad.direction).Add(quad);
		}

		public void Finish() {
			// Detect full block
			fullBlock = true;

			for (var direction = typeof(Direction).MinValue; direction <= typeof(Direction).MaxValue; direction++) {
				List<Quad> quads = GetAdjacentQuads(direction);

				if (quads.IsEmpty) {
					fullBlock = false;
					break;
				}

				for (Quad quad in quads) {
					switch (quad.direction) {
					case .Up, .Down:
						if (quad.min.x != 0 || quad.min.z != 0 || quad.max.x != 1 || quad.max.z != 1) {
							fullBlock = false;
							break;
						}
					case .East, .West:
						if (quad.min.y != 0 || quad.min.z != 0 || quad.max.y != 1 || quad.max.z != 1) {
							fullBlock = false;
							break;
						}
					case .North, .South:
						if (quad.min.x != 0 || quad.min.y != 0 || quad.max.x != 1 || quad.max.y != 1) {
							fullBlock = false;
							break;
						}
					}
				}
			}
		}

		public List<Quad> GetAdjacentQuads(Direction direction) {
			return adjacentQuads[direction.Underlying];
		}
	}
}