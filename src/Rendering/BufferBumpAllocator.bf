using System;
using System.Collections;

using Wgpu;

namespace Meteorite {
	class BufferBumpAllocator {
		private Dictionary<Wgpu.BufferUsage, List<Entry>> buffers = new .();
		private int allocations;

		public ~this() {
			for (let entry in buffers.Values) DeleteContainerAndDisposeItems!(entry);
			delete buffers;
		}

		public WBufferSegment Allocate(Wgpu.BufferUsage usage, uint64 size) {
			List<Entry> entries = GetEntries(usage);
			allocations++;

			for (var entry in ref entries) {
				if (entry.buffer.size - entry.size >= size) {
					WBufferSegment segment = .(entry.buffer, entry.size, size);
					entry.size += size;
					return segment;
				}
			}

			entries.Add(.(Gfx.CreateBuffer(usage, 1024 * 1024, null), size));
			return .(entries.Back.buffer, 0, size);
		}

		public MeshBuilder AllocateImmediate(RenderPass pass, WBuffer ibo = null) => new ImmediateMeshBuilder(pass, this, ibo);

		public void Reset() {
			for (let entries in buffers.Values) {
				for (var entry in ref entries) entry.size = 0;
			}

			allocations = 0;
		}

		private List<Entry> GetEntries(Wgpu.BufferUsage usage) {
			List<Entry> entries = buffers.GetValueOrDefault(usage);

			if (entries == null) {
				entries = new .();
				buffers[usage] = entries;
			}

			return entries;
		}

		private struct Entry : IDisposable {
			public WBuffer buffer;
			public uint64 size;

			public this(WBuffer buffer, uint64 size) {
				this.buffer = buffer;
				this.size = size;
			}

			public void Dispose() {
				delete buffer;
			}
		}
	}
}