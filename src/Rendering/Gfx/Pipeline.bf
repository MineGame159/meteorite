using System;
using System.IO;
using System.Collections;
using Wgpu;

namespace Meteorite {
	enum VertexAttribute {
		case UByte2Float;
		case UByte4;
		case SByte4;

		case UShort2;
		case UShort2Float;

		case Float2;
		case Float3;

		public uint64 GetSize() {
			switch (this) {
			case .UByte2Float: return sizeof(uint8) * 2;
			case .UByte4:      return sizeof(uint8) * 4;
			case .SByte4:      return sizeof(uint8) * 4;

			case .UShort2, .UShort2Float: return sizeof(uint16) * 2;

			case .Float2: return sizeof(float) * 2;
			case .Float3: return sizeof(float) * 3;
			}
		}

		public Wgpu.VertexFormat GetFormat() {
			switch (this) {
			case .UByte2Float: return .Unorm8x2;
			case .UByte4:      return .Unorm8x4;
			case .SByte4:      return .Snorm8x4;

			case .UShort2:      return .Uint16x2;
			case .UShort2Float: return .Unorm16x2;

			case .Float2: return .Float32x2;
			case .Float3: return .Float32x3;
			}
		}
	}

	class Pipeline {
		private PipelineBuilder builder ~ delete _;
		private Wgpu.RenderPipeline handle ~ _.Drop();

		private this(PipelineBuilder builder) {
			this.builder = builder;
			this.handle = builder.[Friend]Build();
		}

		public void Bind(RenderPass pass) => pass.[Friend]encoder.SetPipeline(handle);

		public void Reload() {
			handle.Drop();
			handle = builder.[Friend]Build();
		}
	}

	class PipelineBuilder {
		enum Cull {
			None,
			Clockwise,
			CounterClockwise
		}

		private Wgpu.BindGroupLayout[] bindGroupLayouts ~ delete _;
		private VertexAttribute[] attributes ~ delete _;

		private String shaderPath ~ delete _;
		private delegate void(ShaderPreProcessor) initPreProcessor ~ delete _;

		private Wgpu.ShaderStage stages;
		private int start, end;

		private Wgpu.PrimitiveTopology topology;
		private Cull cull = .None;

		private Wgpu.TextureFormat[] targets ~ delete _;

		private bool blend = true;
		private Wgpu.BlendState? blendState;

		private bool depth, depthTest, depthWrite;

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

		public Self Shader(StringView shader, delegate void(ShaderPreProcessor) initPreProcessor = null) {
			this.shaderPath = new .(shader);
			this.initPreProcessor = initPreProcessor;

			return this;
		}

		public Self PushConstants(Wgpu.ShaderStage stages, int start, int end) {
			this.stages = stages;
			this.start = start;
			this.end = end;

			return this;
		}

		public Self Primitive(Wgpu.PrimitiveTopology topology, Cull cull) {
			this.topology = topology;
			this.cull = cull;

			return this;
		}

		public Self Targets(params Wgpu.TextureFormat[] formats) {
			targets = new .[formats.Count];
			formats.CopyTo(targets);

			return this;
		}

		public Self Blend(bool blend) {
			this.blend = blend;
			return this;
		}

		public Self BlendState(Wgpu.BlendState blendState) {
			this.blendState = blendState;
			return this;
		}

		public Self Depth(bool depth, bool depthTest = true, bool depthWrite = true) {
			this.depth = depth;
			this.depthTest = depthTest;
			this.depthWrite = depthWrite;

			return this;
		}

		public Pipeline Create() => new [Friend].(this);

		private Wgpu.RenderPipeline Build() {
			if (targets == null) Targets(.BGRA8Unorm);

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
			if (blendState != null) blend = blendState.Value;

			Wgpu.ColorTargetState[] targetDescs = scope .[targets.Count];
			for (int i < targets.Count) {
				targetDescs[i] = .() {
					format = targets[i],
					blend = i == 0 ? (this.blend ? &blend : null) : null,
					writeMask = .All
				};
			}

			Wgpu.FragmentState fragmentDesc = .() {
				module = GetShader!(false),
				entryPoint = "main",
				targetCount = (.) targetDescs.Count,
				targets = &targetDescs[0]
			};

			Wgpu.DepthStencilState depthStencil = .() {
				format = .Depth32Float,
				depthWriteEnabled = depthWrite,
				depthCompare = depthTest ? .LessEqual : .Always,
				stencilFront = .() {
					compare = .Always
				},
				stencilBack = .() {
					compare = .Always
				},
			};

			Wgpu.RenderPipelineDescriptor desc = .() {
				vertex = .() {
					module = GetShader!(true),
					entryPoint = "main",
					bufferCount = 1,
					buffers = &vertexBufferLayout
				},
				fragment = &fragmentDesc,
				primitive = .() {
					topology = topology,
					stripIndexFormat = .Undefined,
					frontFace = cull == .CounterClockwise ? .CCW : .CW,
					cullMode = cull == .None ? .None : .Back,
				},
				depthStencil = depth ? &depthStencil : null,
				multisample = .() {
					count = 1,
					mask = ~0
				}
			};

			Wgpu.RenderPipeline pipeline = Gfx.[Friend]CreatePipeline(&layoutDesc, &desc);
			return pipeline;
		}

		private mixin GetShader(bool vertex) {
			StringView ext = vertex ? "vert" : "frag";
			StringView path = scope $"shaders/{shaderPath}.{ext}";

			ShaderPreProcessor preProcessor = scope .();
			preProcessor.Define(vertex ? "VERTEX" : "FRAGMENT");
			initPreProcessor?.Invoke(preProcessor);

			String string = scope .();
			preProcessor.PreProcess(path, string);
			
			Shader shader = Gfx.CreateShaderBuffer(vertex ? .Vertex : .Fragment, string);
			defer:: delete shader;

			shader.[Friend]handle
		}
	}
}