using System;

namespace Cacti.Graphics;

struct BuiltMesh : IDisposable {
	public GpuBufferView vbo;
	public GpuBufferView ibo;
	public uint32 indexCount;

	private bool deleteVbo, deleteIbo;

	public this(GpuBufferView vbo, GpuBufferView ibo, uint32 indexCount, bool deleteVbo, bool deleteIbo) {
		this.vbo = vbo;
		this.ibo = ibo;
		this.indexCount = indexCount;
		this.deleteVbo = deleteVbo;
		this.deleteIbo = deleteIbo;
	}

	public void Dispose() {
		if (deleteVbo && vbo.Valid) vbo.buffer.Release();
		if (deleteIbo && ibo.Valid) ibo.buffer.Release();
	}
}

enum EndBuffer {
	case Frame,
		 Provided(GpuBufferView view),
		 ProvidedResize(GpuBuffer* buffer),
		 Create(StringView name);

	public static operator Self(GpuBufferView view) => .Provided(view);
	public static operator Self(GpuBuffer buffer) => .Provided(buffer);
}

class MeshBuilder {
	private Buffer vertices, indices;
	private GpuBufferView vbo, ibo;

	private uint32 vertexI, indexCount;

	public this(bool buildIndices = true) {
		vertices = Buffers.Get();
		if (buildIndices) indices = Buffers.Get();
	}

	// Vertices

	public uint32 Vertex<T>(T vertex) where T : struct {
		vertices.EnsureCapacity((.) sizeof(T));
		vertices.Add(vertex);
		return vertexI++;
	}

	// Indices

	public void Line(uint32 i1, uint32 i2) {
		indexCount += 2;

		if (indices == null) return;
		indices.EnsureCapacity(8);
		uint32* indices = indices.AddMultiple<uint32>(2);

		indices[0] = i1;
		indices[1] = i2;
	}

	public void Triangle(uint32 i1, uint32 i2, uint32 i3) {
		indexCount += 3;

		if (indices == null) return;
		indices.EnsureCapacity(12);
		uint32* indices = indices.AddMultiple<uint32>(3);

		indices[0] = i1;
		indices[1] = i2;
		indices[2] = i3;
	}

	public void Quad(uint32 i1, uint32 i2, uint32 i3, uint32 i4) {
		indexCount += 6;

		if (indices == null) return;
		indices.EnsureCapacity(24);
		uint32* indices = indices.AddMultiple<uint32>(6);

		indices[0] = i1;
		indices[1] = i2;
		indices[2] = i3;

		indices[3] = i3;
		indices[4] = i4;
		indices[5] = i1;
	}

	// Combined

	public void Line<T>(T v1, T v2) where T : struct {
		Line(
			Vertex(v1),
			Vertex(v2)
		);
	}

	public void Triangle<T>(T v1, T v2, T v3) where T : struct {
		Triangle(
			Vertex(v1),
			Vertex(v2),
			Vertex(v3)
		);
	}

	public void Quad<T>(T v1, T v2, T v3, T v4) where T : struct {
		Quad(
			Vertex(v1),
			Vertex(v2),
			Vertex(v3),
			Vertex(v4)
		);
	}

	// End

	public BuiltMesh End(EndBuffer vbo = .Frame, EndBuffer ibo = .Frame, delegate void() uploadCallback = null) {
		if (indices == null && !(ibo case .Provided)) {
			Log.Error("MeshBuilder.End() called without a provided IBO but the MeshBuilder instance was created with buildIndices set to false");
			return default;
		}

		if ((vbo case .Provided || vbo case .ProvidedResize) || vertices.Size > 0) {
			switch (vbo) {
			case .Frame:						this.vbo = Gfx.FrameAllocator.Allocate(.Vertex, vertices.Size);
			case .Provided(let view):			this.vbo = view;
			case .ProvidedResize(let buffer):	Gfx.Buffers.EnsureSize(ref *buffer, vertices.Size); this.vbo = *buffer;
			case .Create(let name):				this.vbo = Gfx.Buffers.Create(name, .Vertex, .Mappable, vertices.Size).Value;
			}
		}

		if ((ibo case .Provided || ibo case .ProvidedResize) || indices.Size > 0) {
			switch (ibo) {
			case .Frame:						this.ibo = Gfx.FrameAllocator.Allocate(.Index, indices.Size);
			case .Provided(let view):			this.ibo = view;
			case .ProvidedResize(let buffer):	Gfx.Buffers.EnsureSize(ref *buffer, indices.Size); this.ibo = *buffer;
			case .Create(let name):				this.ibo = Gfx.Buffers.Create(name, .Index, .Mappable, indices.Size).Value;
			}
		}

		if (uploadCallback != null) {
			UploadCallback callback = new .(uploadCallback);

			if (vertices.Size > 0) Gfx.Uploads.UploadBuffer(this.vbo, vertices.Data, vertices.Size, callback, false);
			else callback.UploadFinished();

			if (indices != null && indices.Size > 0) Gfx.Uploads.UploadBuffer(this.ibo, indices.Data, indices.Size, callback, false);
			else callback.UploadFinished();
		}
		else {
			if (vertices.Size > 0) this.vbo.Upload(vertices.Data, vertices.Size);
			if (indices != null && indices.Size > 0) this.ibo.Upload(indices.Data, indices.Size);
		}

		BuiltMesh mesh = .(
			this.vbo,
			this.ibo,
			indexCount,
			vbo case .Create,
			ibo case .Create
		);

		Buffers.Return(vertices);
		Buffers.Return(indices);

		return mesh;
	}

	public void Cancel() {
		Buffers.Return(vertices);
		Buffers.Return(indices);
	}

	class UploadCallback {
		private delegate void() callback ~ delete _;
		private delegate void() selfCallback ~ delete _;

		private bool called;

		public this(delegate void() callback) {
			this.callback = callback;
			this.selfCallback = new => UploadFinished;
		}

		public void UploadFinished() {
			if (called) {
				callback();
				delete this;
			}
			else {
				called = true;
			}
		}

		public static operator delegate void()(Self callback) => callback.selfCallback;
	}
}