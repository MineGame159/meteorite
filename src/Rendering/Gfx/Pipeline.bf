using System;
using Wgpu;

namespace Meteorite {
	enum VertexAttributeType {
		UByte,
		Float
	}

	struct VertexAttribute : this(VertexAttributeType type, int count) {
		public uint64 GetSize() {
			uint64 typeSize = 0;
			
			switch (type) {
			case .UByte: typeSize = sizeof(uint8);
			case .Float: typeSize = sizeof(float);
			}

			return typeSize * (.) count;
		}

		public Wgpu.VertexFormat GetFormat() {
			switch (type) {
			case .UByte: return .Unorm8x2 + count - 3;
			case .Float: return .Float32 + count - 1;
			}
		}
	}

	class Pipeline {
		private Wgpu.RenderPipeline handle ~ _.Drop();

		private this(Wgpu.RenderPipeline handle) {
			this.handle = handle;
		}

		public void Bind() => Gfx.[Friend]pass.SetPipeline(handle);
	}

	class PipelineBuilder {
		private Wgpu.BindGroupLayout[] bindGroupLayouts ~ delete _;
		private VertexAttribute[] attributes ~ delete _;

		private Shader vShader, fShader;
		private StringView vEntryPoint, fEntryPoint;

		private Wgpu.ShaderStage stages;
		private int start, end;

		private Wgpu.PrimitiveTopology topology;
		private bool cull;

		private bool depth, depthWrite;

		private this() {}

		public Self BindGroupLayouts(params BindGroupLayout[] bindGroupLayouts) {
			this.bindGroupLayouts = new .[bindGroupLayouts.Count];
			for (int i < bindGroupLayouts.Count) this.bindGroupLayouts[i] = bindGroupLayouts[i].[Friend]handle;

			return this;
		}

		public Self Attributes(params VertexAttribute[] attributes) {
			this.attributes = new .[attributes.Count];
			attributes.CopyTo(this.attributes);

			return this;
		}

		public Self VertexShader(Shader shader, StringView entryPoint) {
			vShader = shader;
			vEntryPoint = entryPoint;

			return this;
		}

		public Self FragmentShader(Shader shader, StringView entryPoint) {
			fShader = shader;
			fEntryPoint = entryPoint;

			return this;
		}

		public Self PushConstants(Wgpu.ShaderStage stages, int start, int end) {
			this.stages = stages;
			this.start = start;
			this.end = end;

			return this;
		}

		public Self Primitive(Wgpu.PrimitiveTopology topology, bool cull) {
			this.topology = topology;
			this.cull = cull;

			return this;
		}

		public Self Depth(bool depth, bool depthWrite = true) {
			this.depth = depth;
			this.depthWrite = depthWrite;

			return this;
		}

		public Pipeline Create() {
			Wgpu.PipelineLayoutDescriptor layoutDesc = .();

			if (bindGroupLayouts != null) {
				layoutDesc.bindGroupLayoutCount = (.) bindGroupLayouts.Count;
				layoutDesc.bindGroupLayouts = &bindGroupLayouts[0];
			}

			Wgpu.VertexAttribute[] attributes = scope .[attributes.Count];
			uint64 stride = 0;

			for (int i < attributes.Count) {
				uint64 size = this.attributes[i].GetSize();

				attributes[i] = .() {
					format = this.attributes[i].GetFormat(),
					offset = stride,
					shaderLocation = (.) i
				};

				stride += size;
			}

			if (stages != .None) {
				Wgpu.PushConstantRange* pushConstantRange = scope:: .() {
					stages = stages,
					start = (.) start,
					end = (.) end
				};

				Wgpu.PipelineLayoutExtras* layoutExtras = scope:: .() {
					chain = .() {
						sType = (.) Wgpu.NativeSType.PipelineLayoutExtras
					},
					pushConstantRangeCount = 1,
					pushConstantRanges = pushConstantRange
				};

				layoutDesc.nextInChain = (.) layoutExtras;
			}

			Wgpu.VertexBufferLayout vertexBufferLayout = .() {
				arrayStride = stride,
				stepMode = .Vertex,
				attributeCount = (.) attributes.Count,
				attributes = &attributes[0]
			};

			Wgpu.BlendState blend = .() {
				color = .(.Add, .SrcAlpha, .OneMinusSrcAlpha),
				alpha = .(.Add, .One, .OneMinusSrcAlpha)
			};
			Wgpu.ColorTargetState colorTarget = .() {
				format = .BGRA8Unorm,
				blend = &blend,
				writeMask = .All
			};
			Wgpu.FragmentState fragmentDesc = .() {
				module = fShader.[Friend]handle,
				entryPoint = fEntryPoint.ToScopeCStr!(),
				targetCount = 1,
				targets = &colorTarget
			};

			Wgpu.DepthStencilState depthStencil = .() {
				format = .Depth32Float,
				depthWriteEnabled = depthWrite,
				depthCompare = .Less,
				stencilFront = .() {
					compare = .Always
				},
				stencilBack = .() {
					compare = .Always
				},
			};

			Wgpu.RenderPipelineDescriptor desc = .() {
				vertex = .() {
					module = vShader.[Friend]handle,
					entryPoint = vEntryPoint.ToScopeCStr!(),
					bufferCount = 1,
					buffers = &vertexBufferLayout
				},
				fragment = &fragmentDesc,
				primitive = .() {
					topology = topology,
					stripIndexFormat = .Undefined,
					frontFace = .CCW,
					cullMode = cull ? .Back : .None,
				},
				depthStencil = depth ? &depthStencil : null,
				multisample = .() {
					count = 1,
					mask = ~0
				}
			};

			Pipeline pipeline = new [Friend].(Gfx.[Friend]CreatePipeline(&layoutDesc, &desc));
			delete this;
			return pipeline;
		}
	}
}