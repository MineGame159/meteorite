using System;

using Cacti;

namespace Meteorite {
	[CRepr]
	struct EntityVertex : this(Vec3f pos, Vec4<int8> normal, Vec2<uint16> uv, Color color) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 3)
			.Attribute(.I8, 4, true)
			.Attribute(.U16, 2, true)
			.Attribute(.U8, 4, true)
			~ delete _;
	}

	class Entity {
		public EntityType type;
		public int id;
		public Vec3d pos;
		public float yaw, pitch;

		public Vec3d trackedPos;
		public Vec3d serverPos;
		public Vec3d lastPos;
		public int bodyTrackingIncrements;

		public Pose pose = .Standing;
		public int tickCount;

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

			Vec3f normal = .(0, 127, 0);
			mb.Quad(
				Vertex!(mb, x1, y2, z1, normal, color),
				Vertex!(mb, x2, y2, z1, normal, color),
				Vertex!(mb, x2, y2, z2, normal, color),
				Vertex!(mb, x1, y2, z2, normal, color)
			);

			normal = .(0, -127, 0);
			mb.Quad(
				Vertex!(mb, x1, y1, z1, normal, color),
				Vertex!(mb, x1, y1, z2, normal, color),
				Vertex!(mb, x2, y1, z2, normal, color),
				Vertex!(mb, x2, y1, z1, normal, color)
			);

			normal = .(127, 0, 0);
			mb.Quad(
				Vertex!(mb, x2, y1, z1, normal, color),
				Vertex!(mb, x2, y1, z2, normal, color),
				Vertex!(mb, x2, y2, z2, normal, color),
				Vertex!(mb, x2, y2, z1, normal, color)
			);

			normal = .(-127, 0, 0);
			mb.Quad(
				Vertex!(mb, x1, y1, z1, normal, color),
				Vertex!(mb, x1, y2, z1, normal, color),
				Vertex!(mb, x1, y2, z2, normal, color),
				Vertex!(mb, x1, y1, z2, normal, color)
			);

			normal = .(0, 0, -127);
			mb.Quad(
				Vertex!(mb, x1, y1, z1, normal, color),
				Vertex!(mb, x2, y1, z1, normal, color),
				Vertex!(mb, x2, y2, z1, normal, color),
				Vertex!(mb, x1, y2, z1, normal, color)
			);

			normal = .(0, 0, 127);
			mb.Quad(
				Vertex!(mb, x1, y1, z2, normal, color),
				Vertex!(mb, x1, y2, z2, normal, color),
				Vertex!(mb, x2, y2, z2, normal, color),
				Vertex!(mb, x2, y1, z2, normal, color)
			);
		}

		private static mixin Vertex(MeshBuilder mb, double x, double y, double z, Vec3f normal, Color color) {
			mb.Vertex<EntityVertex>(.(
				.((.) x, (.) y, (.) z),
				.((.) normal.x, (.) normal.y, (.) normal.z, 0),
				.(0, 0),
				color
			))
		}

		public bool IsInWater() => false;
	}
}