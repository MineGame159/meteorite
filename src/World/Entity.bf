using System;

namespace Meteorite {
	class Entity {
		public EntityType type;
		public int id;
		public Vec3d pos;
		public float yaw, pitch;

		public Vec3d trackedPos;
		public Vec3d serverPos;
		public Vec3d lastPos;
		public int bodyTrackingIncrements;

		public bool noPhysics;

		public this(EntityType type, int id, Vec3d pos) {
			this.type = type;
			this.id = id;
			this.pos = pos;
			this.trackedPos = pos;
			this.lastPos = pos;
		}

		public AABB GetAABB() => .(pos, pos + .(type.width, type.height, type.width));

		public virtual void Tick() {
			lastPos = pos;

			if (bodyTrackingIncrements > 0) {
				pos.x += (serverPos.x - pos.x) / (double) bodyTrackingIncrements;
				pos.y += (serverPos.y - pos.y) / (double) bodyTrackingIncrements;
				pos.z += (serverPos.z - pos.z) / (double) bodyTrackingIncrements;

				bodyTrackingIncrements--;
			}
		}

		public void Render(MeshBuilder mb, double tickDelta) {
			Color color = type.GetColor();

			Vec3d pos = this.pos.Lerp(tickDelta, lastPos);

			double x1 = pos.x - type.width / 2;
			double y1 = pos.y;
			double z1 = pos.z - type.width / 2;

			double x2 = x1 + type.width;
			double y2 = y1 + type.height;
			double z2 = z1 + type.width;

			Color c = color;
			mb.Quad(
				mb.Vec3(.((.) x1, (.) y2, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y2, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y2, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y2, (.) z2)).Color(c).Next()
			);

			c = color.MulWithoutA(0.4f);
			mb.Quad(
				mb.Vec3(.((.) x1, (.) y1, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y1, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y1, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y1, (.) z1)).Color(c).Next()
			);

			c = color.MulWithoutA(0.6f);
			mb.Quad(
				mb.Vec3(.((.) x2, (.) y1, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y1, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y2, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y2, (.) z1)).Color(c).Next()
			);

			mb.Quad(
				mb.Vec3(.((.) x1, (.) y1, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y2, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y2, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y1, (.) z2)).Color(c).Next()
			);

			c = color.MulWithoutA(0.8f);
			mb.Quad(
				mb.Vec3(.((.) x1, (.) y1, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y1, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y2, (.) z1)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y2, (.) z1)).Color(c).Next()
			);

			mb.Quad(
				mb.Vec3(.((.) x1, (.) y1, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x1, (.) y2, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y2, (.) z2)).Color(c).Next(),
				mb.Vec3(.((.) x2, (.) y1, (.) z2)).Color(c).Next()
			);
		}
	}
}