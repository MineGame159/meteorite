using System;

namespace Meteorite {
	enum Planes {
		Left,
		Right,
		Bottom,
		Top,
		Near,
		Far
	}

	struct Plane : this(float distanceToOrigin, Vec3f normal) {
		public float DistanceToPoint(Vec3f min, Vec3f max) {
			Vec3f point = min;

			if (normal.x > 0) point.x = max.x;
			if (normal.y > 0) point.y = max.y;
			if (normal.z > 0) point.z = max.z;

			return point.Dot(normal) + distanceToOrigin;
		}
	}

	class Camera {
		public Mat4 proj, view, viewRotationOnly;

		public Vec3f pos;
		public float yaw, pitch;

		private Plane[6] planes;

		public this() {
			this.yaw = -90;
		}

		public Vec3f GetDirection(bool applyPitch) {
			if (applyPitch) {
				return Vec3f(
					Math.Cos(Math.DEG2RADf * yaw) * Math.Cos(Math.DEG2RADf * pitch),
					Math.Sin(Math.DEG2RADf * pitch),
					Math.Sin(Math.DEG2RADf * yaw) * Math.Cos(Math.DEG2RADf * pitch)
				).Normalize();
			}

			return Vec3f(
				Math.Cos(Math.DEG2RADf * yaw),
				0,
				Math.Sin(Math.DEG2RADf * yaw)
			).Normalize();
		}

		public void Update() {
			Window window = Meteorite.INSTANCE.window;

			int width = window.width;
			int height = window.height;

			if (Screenshots.rendering) {
				width = Screenshots.width;
				height = Screenshots.height;
			}

			// Update matrices
			proj = .Perspective(75, (float) width / height, 0.05f, 2000);
			view = .LookAt(pos, pos + GetDirection(true), .(0, 1, 0));
			viewRotationOnly = .LookAt(.(), GetDirection(true), .(0, 1, 0));

			// Calculate frustum
			Mat4 clip = proj * view;

			planes[(.) Planes.Left].normal.x = clip[0][3] + clip[0][0];
			planes[(.) Planes.Left].normal.y = clip[1][3] + clip[1][0];
			planes[(.) Planes.Left].normal.z = clip[2][3] + clip[2][0];
			planes[(.) Planes.Left].distanceToOrigin = clip[3][3] + clip[3][0];

			planes[(.) Planes.Right].normal.x = clip[0][3] - clip[0][0];
			planes[(.) Planes.Right].normal.y = clip[1][3] - clip[1][0];
			planes[(.) Planes.Right].normal.z = clip[2][3] - clip[2][0];
			planes[(.) Planes.Right].distanceToOrigin = clip[3][3] - clip[3][0];

			planes[(.) Planes.Bottom].normal.x = clip[0][3] + clip[0][1];
			planes[(.) Planes.Bottom].normal.y = clip[1][3] + clip[1][1];
			planes[(.) Planes.Bottom].normal.z = clip[2][3] + clip[2][1];
			planes[(.) Planes.Bottom].distanceToOrigin = clip[3][3] + clip[3][1];

			planes[(.) Planes.Top].normal.x = clip[0][3] - clip[0][1];
			planes[(.) Planes.Top].normal.y = clip[1][3] - clip[1][1];
			planes[(.) Planes.Top].normal.z = clip[2][3] - clip[2][1];
			planes[(.) Planes.Top].distanceToOrigin = clip[3][3] - clip[3][1];

			planes[(.) Planes.Near].normal.x = clip[0][3] + clip[0][2];
			planes[(.) Planes.Near].normal.y = clip[1][3] + clip[1][2];
			planes[(.) Planes.Near].normal.z = clip[2][3] + clip[2][2];
			planes[(.) Planes.Near].distanceToOrigin = clip[3][3] + clip[3][2];

			planes[(.) Planes.Far].normal.x = clip[0][3] - clip[0][2];
			planes[(.) Planes.Far].normal.y = clip[1][3] - clip[1][2];
			planes[(.) Planes.Far].normal.z = clip[2][3] - clip[2][2];
			planes[(.) Planes.Far].distanceToOrigin = clip[3][3] - clip[3][2];

			/*for (ref Plane plane in ref planes) {
			    float length = plane.normal.Length;
			    plane.normal /= length;
			    plane.distanceToOrigin /= length;
			}*/
		}

		public void FlightMovement(float delta) {
			// Rotation
			if (Meteorite.INSTANCE.window.MouseHidden) {
				yaw += Input.mouseDelta.x / 7;
				pitch -= Input.mouseDelta.y / 7;

				pitch = Math.Clamp(pitch, -89.5f, 89.5f);
			}

			// Movement
			float speed = 10 * delta;
			if (Input.IsKeyDown(.LeftControl)) speed *= 10;

			Vec3f forward = GetDirection(false);
			Vec3f right = forward.Cross(.(0, 1, 0)).Normalize();

			forward *= speed;
			right *= speed;

			if (Input.IsKeyDown(.W)) pos -= forward;
			if (Input.IsKeyDown(.S)) pos += forward;
			if (Input.IsKeyDown(.D)) pos -= right;
			if (Input.IsKeyDown(.A)) pos += right;
			if (Input.IsKeyDown(.Space)) pos.y += speed;
			if (Input.IsKeyDown(.LeftShift)) pos.y -= speed;
		}

		public bool IsBoxVisible(Vec3f min, Vec3f max) {
			for (Plane plane in planes) {
			    if (plane.DistanceToPoint(min, max) < 0) return false;
			}

			return true;
		}
	}
}