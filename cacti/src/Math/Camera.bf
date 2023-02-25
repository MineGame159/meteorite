using System;

namespace Cacti;

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

		return (.) point.Dot(normal) + distanceToOrigin;
	}
}

class Camera {
	public Mat4 proj2d;
	public Mat4 proj, view, viewRotationOnly;

	public Vec3d pos;
	public float yaw, pitch;
	public float fov;

	public float nearClip = 0.05f, farClip;
	private Plane[6] planes;

	private Window window;

	public this(Window window) {
		this.yaw = -90;
		this.fov = 75;
		this.window = window;
	}

	private Vec3<T> GetDirection<T>(bool applyPitch) where T : var {
		if (applyPitch) {
			return Vec3<T>(
				Math.Cos(Math.DEG2RADf * yaw) * Math.Cos(Math.DEG2RADf * pitch),
				Math.Sin(Math.DEG2RADf * pitch),
				Math.Sin(Math.DEG2RADf * yaw) * Math.Cos(Math.DEG2RADf * pitch)
			).Normalize();
		}

		return Vec3<T>(
			Math.Cos(Math.DEG2RADf * yaw),
			0,
			Math.Sin(Math.DEG2RADf * yaw)
		).Normalize();
	}

	public Vec3f GetDirection(bool applyPitch) => GetDirection<float>(applyPitch);

	public void Update(float far) {
		farClip = far;

		int width = window.Width;
		int height = window.Height;

		// Update matrices
		Vec3f posF = .((.) pos.x, (.) pos.y, (.) pos.z);

		proj2d = .Ortho(0, width / 2, 0, height / 2);
		proj = .Perspective(fov, (float) width / height, nearClip, farClip);
		view = .LookAt(posF, posF + GetDirection(true), .(0, 1, 0));
		viewRotationOnly = .LookAt(.ZERO, GetDirection(true), .(0, 1, 0));

		// Calculate frustum
		Mat4 clip = proj * viewRotationOnly;

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

		for (ref Plane plane in ref planes) {
		    float length = (.) plane.normal.Length;
		    plane.normal /= length;
		    plane.distanceToOrigin /= length;
		}
	}

	public void FlightMovement(float delta) {
		// Rotation
		if (window.MouseHidden) {
			yaw += Input.mouseDelta.x / 7;
			pitch -= Input.mouseDelta.y / 7;

			pitch = Math.Clamp(pitch, -89.5f, 89.5f);
		}

		// Movement
		float speed = 10 * delta;
		if (Input.IsKeyDown(.LeftControl)) speed *= 10;

		Vec3d forward = GetDirection<double>(false);
		Vec3d right = forward.Cross(.(0, -1, 0)).Normalize();

		forward *= speed;
		right *= speed;

		if (Input.IsKeyDown(.W)) pos -= forward;
		if (Input.IsKeyDown(.S)) pos += forward;
		if (Input.IsKeyDown(.D)) pos += right;
		if (Input.IsKeyDown(.A)) pos -= right;
		if (Input.IsKeyDown(.Space)) pos.y += speed;
		if (Input.IsKeyDown(.LeftShift)) pos.y -= speed;
	}

	public bool IsBoxVisible(Vec3f min, Vec3f max) {
		for (let plane in planes) {
		    if (plane.DistanceToPoint(min, max) < 0) return false;
		}

		return true;
	}

	public bool IsBoxVisible(Vec3d min, Vec3d max) => IsBoxVisible((Vec3f) min, (Vec3f) max);
}