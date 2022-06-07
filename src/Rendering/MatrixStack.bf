using System;
using System.Collections;

namespace Meteorite {
	class MatrixStack {
		private List<Entry> matrices = new .() ~ delete _;

		public this() {
			matrices.Add(.());
		}

		public void Push() => matrices.Add(matrices.Back);
		public void Pop() => matrices.PopBack();

		public Mat4 Back => matrices.Back.pos;
		public Mat4 BackNormal => matrices.Back.normal;

		public void Translate(Vec3f vec) {
			ref Entry entry = ref matrices.Back;
			entry.pos = entry.pos.Translate(vec);
		}

		public void Scale(Vec3f vec) {
			ref Entry entry = ref matrices.Back;

			entry.pos = entry.pos.Scale(vec);

			if (vec.x == vec.y && vec.y == vec.z) {
				if (vec.x > 0) return;

				entry.normal *= -1f;
			}

			Vec3f v = 1f / vec;
			float i = 1f / Math.Pow(v.x * v.y * v.z, 1f / 3f);
			entry.normal = entry.normal.Scale(v * i);
		}

		public void Rotate(Vec3f vec, float angle) {
			ref Entry entry = ref matrices.Back;

			entry.pos = entry.pos.Rotate(vec, angle);
			entry.normal = entry.normal.Rotate(vec, angle);
		}

		private struct Entry {
			public Mat4 pos, normal;

			public this() {
				pos = normal = .Identity();
			}
		}
	}
}