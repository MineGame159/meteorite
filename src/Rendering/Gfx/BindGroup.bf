using System;
using Wgpu;

namespace Meteorite {
	class BindGroup {
		private Wgpu.BindGroup handle ~ _.Drop();

		private this(Wgpu.BindGroup handle) {
			this.handle = handle;
		}

		public void Bind(int index = 0) {
			Gfx.[Friend]pass.SetBindGroup((.) index, handle, 0, null);
		}
	}

	class BindGroupLayout {
		private readonly Wgpu.BindGroupLayout handle ~ _.Drop();

		private this(Wgpu.BindGroupLayout handle) {
			this.handle = handle;
		}

		public BindGroup Create(params Object[] args) {
			Wgpu.BindGroupEntry[] entries = scope .[args.Count];

			for (int i < args.Count) {
				entries[i].binding = (.) i;

				if (args[i] is Sampler) entries[i].sampler = ((Sampler) args[i]).[Friend]handle;
				else if (args[i] is Texture) entries[i].textureView = ((Texture) args[i]).[Friend]view;
				else if (args[i] is WBuffer) entries[i].buffer = ((WBuffer) args[i]).[Friend]handle;
				else Log.Error("Unknown bind group entry argument: {}", args[i].GetType());
			}

			return new [Friend].(Gfx.[Friend]CreateBindGroup(handle, entries));
		}
	}

	class BindGroupLayoutBuilder {
		private Wgpu.BindGroupLayoutEntry[8] entries;
		private int count;

		private this() {}

		public Self Texture() {
			entries[count++] = .() {
				binding = (.) count - 1,
				visibility = .Fragment,
				texture = .() {
					sampleType = .Float,
					viewDimension = ._2D
				}
			};

			return this;
		}

		public Self Sampler(Wgpu.SamplerBindingType type) {
			entries[count++] = .() {
				binding = (.) count - 1,
				visibility = .Fragment,
				sampler = .() {
					type = type
				}
			};

			return this;
		}

		public Self Buffer(Wgpu.BufferBindingType type) {
			entries[count++] = .() {
				binding = (.) count - 1,
				visibility = .Vertex,
				buffer = .() {
					type = type
				}
			};

			return this;
		}

		public BindGroupLayout Create() {
			BindGroupLayout layout = new [Friend].(Gfx.[Friend]CreateBindGroupLayout(.(&entries, count)));
			delete this;
			return layout;
		}
	}
}