using System;

namespace Meteorite {
	class Mesh {
		private WBuffer vbo, ibo;
		private bool externalIndices;

		private Buffer vertices;
		private Buffer indices;

		private uint32 verticesI;
		private uint32 indicesCount, renderIndicesCount;
		private bool building;

		public this(WBuffer ibo = null) {
			this.ibo = ibo;
			this.externalIndices = ibo != null;
		}

		public ~this() {
			if (!externalIndices) delete ibo;
			delete vbo;
		}

		public void Begin() {
			vertices = Buffers.Get();
			if (!externalIndices) indices = Buffers.Get();

			vertices.Clear();
			if (!externalIndices) indices.Clear();

			verticesI = 0;
			indicesCount = 0;

			building = true;
		}

		public Self UByte2(uint8 x, uint8 y) {
			vertices.UByte(x);
			vertices.UByte(y);

			return this;
		}

		public Self UShort2(uint16 x, uint16 y) {
			vertices.UShort(x);
			vertices.UShort(y);

			return this;
		}

		public Self UInt(uint32 v) {
			vertices.UInt(v);
			return this;
		}

		public Self Float(float v) {
			vertices.Float(v);
			return this;
		}

		public Self Vec2(Vec2 v) {
			vertices.Float(v.x);
			vertices.Float(v.y);

			return this;
		}

		public Self Vec3(Vec3f v) {
			vertices.Float(v.x);
			vertices.Float(v.y);
			vertices.Float(v.z);

			return this;
		}

		public Self Color(Color v) {
			vertices.UByte(v.r);
			vertices.UByte(v.g);
			vertices.UByte(v.b);
			vertices.UByte(v.a);

			return this;
		}

		public uint32 Next() {
			vertices.EnsureCapacity(64);
			if (!externalIndices) indices.EnsureCapacity(64);

			return verticesI++;
		}

		public void Line(uint32 i1, uint32 i2) {
			if (!externalIndices) {
				indices.UInt(i1);
				indices.UInt(i2);
			}

			indicesCount += 2;
		}

		public void Triangle(uint32 i1, uint32 i2, uint32 i3) {
			if (!externalIndices) {
				indices.UInt(i1);
				indices.UInt(i2);
				indices.UInt(i3);
			}

			indicesCount += 3;
		}

		public void Quad(uint32 i1, uint32 i2, uint32 i3, uint32 i4) {
			Triangle(i1, i2, i3);
			Triangle(i3, i4, i1);
		}

		public void End(bool upload = true) {
			if (upload) {
				if (vbo == null || vertices.size > (.) vbo.size) {
					if (vbo != null) delete vbo;
					vbo = Gfx.CreateBuffer(.Vertex | .CopyDst, vertices.size, vertices.data);
				}
				else {
					vbo.Write(vertices.data, vertices.size);
				}
	
				if (!externalIndices) {
					if (ibo == null || indices.size > (.) ibo.size) {
						if (ibo != null) delete ibo;
						ibo = Gfx.CreateBuffer(.Index | .CopyDst, indices.size, indices.data);
					}
					else {
						ibo.Write(indices.data, indices.size);
					}
				}
	
				renderIndicesCount = indicesCount;
			}

			Buffers.Return(vertices);
			if (!externalIndices) Buffers.Return(indices);

			building = false;
		}

		public void Render() {
			if (renderIndicesCount > 0 && !building) {
				vbo.Bind();
				ibo.Bind();
				Gfx.Draw(renderIndicesCount);
			}
		}
	}
}