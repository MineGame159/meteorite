using System;

namespace Cacti {
	[Union]
	struct Mat4 : IEquatable, IEquatable<Mat4>, IHashable {
		public Vec4f[4] vecs;
		public float[16] floats;

		public this(Vec4f v1, Vec4f v2, Vec4f v3, Vec4f v4) {
			vecs[0] = v1;
			vecs[1] = v2;
			vecs[2] = v3;
			vecs[3] = v4;
		}

		public this() : this(.(), .(), .(), .()) {}

		public static Mat4 Identity() {
			return .(
				.(1, 0, 0, 0),
				.(0, 1, 0, 0),
				.(0, 0, 1, 0),
				.(0, 0, 0, 1)
			);
		}

		public static Mat4 Ortho(float left, float right, float bottom, float top) {
			return .(
				.(2 / (right - left), 0, 0, 0),
				.(0, 2 / (top - bottom), 0, 0),
				.(0, 0, -1, 0),
				.(-(right + left) / (right - left), -(top + bottom) / (top - bottom), 0, 1)
			);
		}

		public static Mat4 Ortho(float left, float right, float bottom, float top, float near, float far) {
			return .(
				.(2 / (right - left), 0, 0, 0),
				.(0, 2 / (top - bottom), 0, 0),
				.(0, 0, -1, 0),
				.(-(right + left) / (right - left), -(top + bottom) / (top - bottom), near / (far - near), 1)
			);
		}

		public Vec4f this[int index] {
			get => vecs[index];
			set mut => vecs[index] = value;
		}

		public ref Vec4f this[int index] {
			get mut => ref vecs[index];
		}

		public static Mat4 Perspective(float fovy, float aspect, float near, float far) {
			float tanHalfFovy = Math.Tan((fovy * Math.DEG2RADf) / 2);

			Mat4 m = .();

			// RH_ZO
			m[0][0] = 1 / (aspect * tanHalfFovy);
			m[1][1] = 1 / (tanHalfFovy);
			m[2][2] = far / (near - far);
			m[2][3] = -1;
			m[3][2] = -(far * near) / (far - near);

			// RH_NO
			/*m[0][0] = 1 / (aspect * tanHalfFovy);
			m[1][1] = 1 / (tanHalfFovy);
			m[2][2] = - (far + near) / (far - near);
			m[2][3] = - 1;
			m[3][2] = - (2 * far * near) / (far - near);*/

			return m;
		}

		public static Mat4 LookAt(Vec3f eye, Vec3f center, Vec3f up) {
			Vec3f f = (center - eye).Normalize();
			Vec3f s = up.Cross(f).Normalize();
			Vec3f u = f.Cross(s);

			Mat4 m = .Identity();
			m.vecs[0].x = s.x;
			m.vecs[1].x = s.y;
			m.vecs[2].x = s.z;
			m.vecs[0].y = u.x;
			m.vecs[1].y = u.y;
			m.vecs[2].y = u.z;
			m.vecs[0].z = f.x;
			m.vecs[1].z = f.y;
			m.vecs[2].z = f.z;
			m.vecs[3].x = -s.Dot(eye);
			m.vecs[3].y = -u.Dot(eye);
			m.vecs[3].z = -f.Dot(eye);
			return m;
		}

		public Mat4 Translate(Vec3f v) {
			Mat4 m = this;
			m.vecs[3] = m.vecs[0] * v.x + m.vecs[1] * v.y + m.vecs[2] * v.z + m.vecs[3];
			return m;
		}

		public Mat4 Rotate(Vec3f v, float angle) {
			float a = angle * Math.DEG2RADf;
			float c = Math.Cos(a);
			float s = Math.Sin(a);

			Vec3f axis = v.Normalize();
			Vec3f temp = (1 - c) * axis;

			Mat4 rotate = .();
			rotate.vecs[0].x = c + temp.x * axis.x;
			rotate.vecs[0].y = temp.x * axis.y + s * axis.z;
			rotate.vecs[0].z = temp.x * axis.z - s * axis.y;

			rotate.vecs[1].x = temp.y * axis.x - s * axis.z;
			rotate.vecs[1].y = c + temp.y * axis.y;
			rotate.vecs[1].z = temp.y * axis.z + s * axis.x;

			rotate.vecs[2].x = temp.z * axis.x + s * axis.y;
			rotate.vecs[2].y = temp.z * axis.y - s * axis.x;
			rotate.vecs[2].z = c + temp.z * axis.z;

			return .(
				vecs[0] * rotate.vecs[0].x + vecs[1] * rotate.vecs[0].y + vecs[2] * rotate.vecs[0].z,
				vecs[0] * rotate.vecs[1].x + vecs[1] * rotate.vecs[1].y + vecs[2] * rotate.vecs[1].z,
				vecs[0] * rotate.vecs[2].x + vecs[1] * rotate.vecs[2].y + vecs[2] * rotate.vecs[2].z,
				vecs[3]
			);
		}

		public Mat4 Scale(Vec3f v) {
			return .(
				vecs[0] * v.x,
				vecs[1] * v.y,
				vecs[2] * v.z,
				vecs[3]
			);
		}

		public Mat4 InverseTranspose() {
			float SubFactor00 = this[2][2] * this[3][3] - this[3][2] * this[2][3];
			float SubFactor01 = this[2][1] * this[3][3] - this[3][1] * this[2][3];
			float SubFactor02 = this[2][1] * this[3][2] - this[3][1] * this[2][2];
			float SubFactor03 = this[2][0] * this[3][3] - this[3][0] * this[2][3];
			float SubFactor04 = this[2][0] * this[3][2] - this[3][0] * this[2][2];
			float SubFactor05 = this[2][0] * this[3][1] - this[3][0] * this[2][1];
			float SubFactor06 = this[1][2] * this[3][3] - this[3][2] * this[1][3];
			float SubFactor07 = this[1][1] * this[3][3] - this[3][1] * this[1][3];
			float SubFactor08 = this[1][1] * this[3][2] - this[3][1] * this[1][2];
			float SubFactor09 = this[1][0] * this[3][3] - this[3][0] * this[1][3];
			float SubFactor10 = this[1][0] * this[3][2] - this[3][0] * this[1][2];
			float SubFactor11 = this[1][0] * this[3][1] - this[3][0] * this[1][1];
			float SubFactor12 = this[1][2] * this[2][3] - this[2][2] * this[1][3];
			float SubFactor13 = this[1][1] * this[2][3] - this[2][1] * this[1][3];
			float SubFactor14 = this[1][1] * this[2][2] - this[2][1] * this[1][2];
			float SubFactor15 = this[1][0] * this[2][3] - this[2][0] * this[1][3];
			float SubFactor16 = this[1][0] * this[2][2] - this[2][0] * this[1][2];
			float SubFactor17 = this[1][0] * this[2][1] - this[2][0] * this[1][1];

			Mat4 inverse = ?;
			inverse[0][0] = + (this[1][1] * SubFactor00 - this[1][2] * SubFactor01 + this[1][3] * SubFactor02);
			inverse[0][1] = - (this[1][0] * SubFactor00 - this[1][2] * SubFactor03 + this[1][3] * SubFactor04);
			inverse[0][2] = + (this[1][0] * SubFactor01 - this[1][1] * SubFactor03 + this[1][3] * SubFactor05);
			inverse[0][3] = - (this[1][0] * SubFactor02 - this[1][1] * SubFactor04 + this[1][2] * SubFactor05);

			inverse[1][0] = - (this[0][1] * SubFactor00 - this[0][2] * SubFactor01 + this[0][3] * SubFactor02);
			inverse[1][1] = + (this[0][0] * SubFactor00 - this[0][2] * SubFactor03 + this[0][3] * SubFactor04);
			inverse[1][2] = - (this[0][0] * SubFactor01 - this[0][1] * SubFactor03 + this[0][3] * SubFactor05);
			inverse[1][3] = + (this[0][0] * SubFactor02 - this[0][1] * SubFactor04 + this[0][2] * SubFactor05);

			inverse[2][0] = + (this[0][1] * SubFactor06 - this[0][2] * SubFactor07 + this[0][3] * SubFactor08);
			inverse[2][1] = - (this[0][0] * SubFactor06 - this[0][2] * SubFactor09 + this[0][3] * SubFactor10);
			inverse[2][2] = + (this[0][0] * SubFactor07 - this[0][1] * SubFactor09 + this[0][3] * SubFactor11);
			inverse[2][3] = - (this[0][0] * SubFactor08 - this[0][1] * SubFactor10 + this[0][2] * SubFactor11);

			inverse[3][0] = - (this[0][1] * SubFactor12 - this[0][2] * SubFactor13 + this[0][3] * SubFactor14);
			inverse[3][1] = + (this[0][0] * SubFactor12 - this[0][2] * SubFactor15 + this[0][3] * SubFactor16);
			inverse[3][2] = - (this[0][0] * SubFactor13 - this[0][1] * SubFactor15 + this[0][3] * SubFactor17);
			inverse[3][3] = + (this[0][0] * SubFactor14 - this[0][1] * SubFactor16 + this[0][2] * SubFactor17);

			float determinant = + this[0][0] * inverse[0][0] + this[0][1] * inverse[0][1] + this[0][2] * inverse[0][2] + this[0][3] * inverse[0][3];
			inverse /= determinant;

			return inverse;
		}

		public bool Equals(Object o) => (o is Mat4) ? Equals((Mat4) o) : false;
		public bool Equals(Mat4 m) => vecs[0] == m.vecs[0] && vecs[1] == m.vecs[1] && vecs[2] == m.vecs[2] && vecs[3] == m.vecs[3];

		public int GetHashCode() => vecs[0].GetHashCode() + vecs[1].GetHashCode() + vecs[2].GetHashCode() + vecs[3].GetHashCode();

		public static Self operator*(Self lhs, Self rhs) {
			return .(
				lhs[0] * rhs[0][0] + lhs[1] * rhs[0][1] + lhs[2] * rhs[0][2] + lhs[3] * rhs[0][3],
				lhs[0] * rhs[1][0] + lhs[1] * rhs[1][1] + lhs[2] * rhs[1][2] + lhs[3] * rhs[1][3],
				lhs[0] * rhs[2][0] + lhs[1] * rhs[2][1] + lhs[2] * rhs[2][2] + lhs[3] * rhs[2][3],
				lhs[0] * rhs[3][0] + lhs[1] * rhs[3][1] + lhs[2] * rhs[3][2] + lhs[3] * rhs[3][3]
			);
		}

		public static Self operator*(Self lhs, float rhs) {
			Self mat = lhs;

			mat[0] *= rhs;
			mat[1] *= rhs;
			mat[2] *= rhs;
			mat[3] *= rhs;

			return mat;
		}

		public static Vec4f operator*(Self lhs, Vec4f rhs) {
			let mov0 = rhs[0];
			let mov1 = rhs[1];
			let mul0 = lhs[0] * mov0;
			let mul1 = lhs[1] * mov1;
			let add0 = mul0 + mul1;
			let mov2 = rhs[2];
			let mov3 = rhs[3];
			let mul2 = lhs[2] * mov2;
			let mul3 = lhs[3] * mov3;
			let add1 = mul2 + mul3;
			let add2 = add0 + add1;
			return add2;
		}

		public static Mat4 operator/(Self lhs, float rhs) {
			Self mat = lhs;

			mat[0] /= rhs;
			mat[1] /= rhs;
			mat[2] /= rhs;
			mat[3] /= rhs;

			return mat;
		}
	}
}