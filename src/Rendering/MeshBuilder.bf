using System;

namespace Meteorite {
	abstract class MeshBuilder {
		protected Buffer vertices, indices;
		private uint32 verticesI;

		public uint32 indicesCount;

		public this(Buffer vertices, Buffer indices) {
			this.vertices = vertices;
			this.indices = indices;

			vertices.Clear();
			if (indices != null) indices.Clear();
		}

		public abstract void Finish();

		public abstract void Cancel();

		// Vertices

		public Self UByte2(uint8 x, uint8 y) {
			vertices.UByte(x);
			vertices.UByte(y);

			return this;
		}

		public Self Byte4(int8 x, int8 y, int8 z, int8 w) {
			vertices.Byte(x);
			vertices.Byte(y);
			vertices.Byte(z);
			vertices.Byte(w);

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

		public Self Vec2(Vec2f v) {
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
			if (indices != null) indices.EnsureCapacity(64);

			return verticesI++;
		}

		// Indices

		public void Line(uint32 i1, uint32 i2) {
			if (indices != null) {
				indices.UInt(i1);
				indices.UInt(i2);
			}

			indicesCount += 2;
		}

		public void Triangle(uint32 i1, uint32 i2, uint32 i3) {
			if (indices != null) {
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
	}

	class ImmediateMeshBuilder : MeshBuilder {
		private RenderPass pass;
		private BufferBumpAllocator allocator;
		private WBuffer ibo;

		public this(RenderPass pass, BufferBumpAllocator allocator, WBuffer ibo = null) : base(Buffers.Get(), ibo != null ? null : Buffers.Get()) {
			this.pass = pass;
			this.allocator = allocator;
			this.ibo = ibo;
		}

		public override void Finish() {
			WBufferSegment vbo = allocator.Allocate(.Vertex | .CopyDst, (.) vertices.size);
			vbo.Write(vertices.data, vertices.size);
			vbo.Bind(pass);

			if (this.ibo == null) {
				WBufferSegment ibo = allocator.Allocate(.Index | .CopyDst, (.) indices.size);
				ibo.Write(indices.data, indices.size);
				ibo.Bind(pass);
			}
			else {
				this.ibo.Bind(pass);
			}

			pass.Draw(indicesCount);
			Cancel();
		}

		public override void Cancel() {
			Buffers.Return(vertices);
			Buffers.Return(indices);

			delete this;
		}
	}
}