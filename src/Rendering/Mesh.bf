using System;

namespace Meteorite {
	class Mesh {
		private WBuffer vbo, ibo;
		private bool externalIndices;

		private uint32 indicesCount;
		private MeshBuilder mb;

		public this(WBuffer ibo = null) {
			this.ibo = ibo;
			this.externalIndices = ibo != null;
		}

		public ~this() {
			if (!externalIndices) delete ibo;
			delete vbo;
		}

		public MeshBuilder Build() {
			if (mb != null) return mb;
			return mb = new MyMeshBuilder(this);
		}

		private void Upload() {
			if (vbo == null || mb.[Friend]vertices.size > (.) vbo.size) {
				if (vbo != null) delete vbo;
				vbo = Gfx.CreateBuffer(.Vertex | .CopyDst, mb.[Friend]vertices.size, mb.[Friend]vertices.data);
			}
			else {
				vbo.Write(mb.[Friend]vertices.data, mb.[Friend]vertices.size);
			}

			if (!externalIndices) {
				if (ibo == null || mb.[Friend]indices.size > (.) ibo.size) {
					if (ibo != null) delete ibo;
					ibo = Gfx.CreateBuffer(.Index | .CopyDst, mb.[Friend]indices.size, mb.[Friend]indices.data);
				}
				else {
					ibo.Write(mb.[Friend]indices.data, mb.[Friend]indices.size);
				}
			}

			indicesCount = mb.indicesCount;
			mb = null;
		}

		public void Render(RenderPass pass) {
			if (indicesCount > 0) {
				vbo?.Bind(pass);
				ibo?.Bind(pass);

				pass.Draw(indicesCount);
			}
		}

		class MyMeshBuilder : MeshBuilder {
			private Mesh mesh;

			public this(Mesh mesh) : base(Buffers.Get(), mesh.externalIndices ? null : Buffers.Get()) {
				this.mesh = mesh;
			}

			public override void Finish() {
				mesh.Upload();
				Cancel();
			}

			public override void Cancel() {
				Buffers.Return(vertices);
				Buffers.Return(indices);

				mesh.mb = null;
				delete this;
			}
		}
	}
}