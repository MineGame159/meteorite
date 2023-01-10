using System;
using System.IO;

using Shaderc;
using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti;

enum Primitive {
	case Traingles,
		 Lines,
		 Points;
	
	public VkPrimitiveTopology Vk { get {
		switch (this) {
		case .Traingles:	return .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
		case .Lines:		return .VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
		case .Points:		return .VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
		}
	} }
}

enum PolygonMode {
	case Fill,
		 Line,
		 Point;
	
	public VkPolygonMode Vk { get {
		switch (this) {
		case .Fill:		return .VK_POLYGON_MODE_FILL;
		case .Line:		return .VK_POLYGON_MODE_LINE;
		case .Point:	return .VK_POLYGON_MODE_POINT;
		}
	} }
}

enum CullMode {
	case None,
		 Front,
		 Back;
	
	public VkCullModeFlags Vk { get {
		switch (this) {
		case .None:		return .VK_CULL_MODE_NONE;
		case .Front:	return .VK_CULL_MODE_FRONT_BIT;
		case .Back:		return .VK_CULL_MODE_BACK_BIT;
		}
	} }
}

enum FrontFace {
	case Clockwise,
		 CounterClockwise;
	
	public VkFrontFace Vk { get {
		switch (this) {
		case .Clockwise:		return .VK_FRONT_FACE_CLOCKWISE;
		case .CounterClockwise:	return .VK_FRONT_FACE_COUNTER_CLOCKWISE;
		}
	} }
}

enum BlendOp {
	case Add;

	public VkBlendOp Vk { get {
		return .VK_BLEND_OP_ADD;
	} }
}

enum BlendFactor {
	case SrcAlpha,
		 OneMinusSrcAlpha,
		 One,
		 Zero;

	public VkBlendFactor Vk { get {
		switch (this) {
		case .SrcAlpha:			return .VK_BLEND_FACTOR_SRC_ALPHA;
		case .OneMinusSrcAlpha:	return .VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
		case .One:				return .VK_BLEND_FACTOR_ONE;
		case .Zero:				return .VK_BLEND_FACTOR_ZERO;
		}
	} }
}

struct BlendMode : this(BlendOp op, BlendFactor src, BlendFactor dst) {}

class Pipeline {
	private PipelineBuilder builder ~ delete _;
	private VkPipeline handle ~ vkDestroyPipeline(Gfx.Device, _, null);

	public PipelineLayout layout;

	private this(PipelineBuilder builder, VkPipeline handle, PipelineLayout layout) {
		this.builder = builder;
		this.handle = handle;
		this.layout = layout;
	}

	public Result<void> Reload() {
		switch (builder.[Friend]CreateRaw()) {
		case .Ok(let val):
			VkPipeline handleToDestroy = handle;
			//Gfx.RunBeforeNextFrame(new () => vkDestroyPipeline(Gfx.Device, handleToDestroy, null));

			handle = val.0;
			layout = val.1;
			return .Ok;
		case .Err:
			return .Err;
		}
	}
}

typealias ShaderReadResult = Shaderc.IncludeResult;
typealias ShaderReadCallback = delegate ShaderReadResult*(StringView path);

class PipelineManager {
	private Shaderc.CompileOptions options = new .() ~ delete _;
	private ShaderReadCallback readCallback ~ delete _;

	public this() {
#if DEBUG
		options.SetOptimizationLevel(.Zero);
#elif RELEASE
		options.SetOptimizationLevel(.Performance);
#endif
		readCallback = new (path) => {
			String buffer = scope .();
			let result = File.ReadAllText(path, buffer);

			switch (result) {
			case .Ok:	return ShaderReadResult.New(path, buffer);
			case .Err:	return ShaderReadResult.New("", "");
			}
		};

		options.SetIncludeCallbacks(
			new (userData, requestedSource, type, requestingSource, includeDepth) => {
				String path = scope .();

				if (type == .Standard) Path.InternalCombine(path, requestedSource);
				else {
					String dir = scope .();
					Path.GetDirectoryPath(requestingSource, dir);

					Path.InternalCombine(path, dir, requestedSource);
				}
				
				return readCallback(path);
			},
			new (userData, includeResult) => {
				includeResult.Dispose();
			}
		);
	}

	public void SetReadCallback(ShaderReadCallback callback) {
		delete this.readCallback;
		this.readCallback = callback;
	}

	public PipelineBuilder New(StringView name) {
		return new [Friend].(this, name);
	}
}

struct ShaderPreProcessor {
	private Shaderc.CompileOptions options;

	private this(Shaderc.CompileOptions options) {
		this.options = options;
	}

	public void Define(StringView name) {
		options.AddMacroDefinition(name, "TRUE");
	}
}

delegate void ShaderPreProcessCallback(ShaderPreProcessor preProcessor);

class PipelineBuilder {
	private PipelineManager manager;
	private String name ~ delete _;

	private VkVertexInputBindingDescription inputBinding;
	private VkVertexInputAttributeDescription[] inputAttributes ~ delete _;

	private DescriptorSetLayout[4] sets;
	private uint32 pushConstantsSize;

	private String vertShader = new .() ~ delete _;
	private String fragShader = new .() ~ delete _;
	private ShaderPreProcessCallback shaderCompileCallback ~ delete _;
	private bool shaderPath;

	private ImageFormat[] targets = new .[] (.BGRA) ~ delete _;

	private Primitive primitive = .Traingles;
	private PolygonMode polygonMode = .Fill;
	private CullMode cullMode = .Back;
	private FrontFace frontFace = .CounterClockwise;

	private bool depth, depthTest, depthWrite;
	private bool blend = true;
	private BlendMode colorBlend = .(.Add, .SrcAlpha, .OneMinusSrcAlpha);
	private BlendMode alphaBlend = .(.Add, .One, .Zero);

	private this(PipelineManager manager, StringView name) {
		this.manager = manager;
		this.name = new .(name);
	}

	public Self VertexFormat(VertexFormat format) {
		inputBinding = .() {
			binding = 0,
			stride = (.) format.size,
			inputRate = .VK_VERTEX_INPUT_RATE_VERTEX
		};

		inputAttributes = new .[format.attributes.Count];
		uint32 offset = 0;

		for (int i < inputAttributes.Count) {
			GVertexAttribute attribute = format.attributes[i];

			inputAttributes[i] = .() {
				binding = 0,
				location = (.) i,
				format = attribute.VkFormat,
				offset = offset
			};

			offset += (.) attribute.Size;
		}
		
		return this;
	}

	public Self Sets(params DescriptorSetLayout[] sets) {
		for (int i < sets.Count) {
			if (i >= 4) break;

			this.sets[i] = sets[i];
		}

		return this;
	}

	public Self PushConstants(uint32 size) {
		this.pushConstantsSize = size;

		return this;
	}

	public Self PushConstants<T>() => PushConstants((.) sizeof(T));

	public Self Shader(StringView vertShader, StringView fragShader, ShaderPreProcessCallback compileCallback = null, bool path = true) {
		this.vertShader.Set(vertShader);
		this.fragShader.Set(fragShader);
		this.shaderCompileCallback = compileCallback;
		this.shaderPath = path;

		return this;
	}

	public Self Targets(params ImageFormat[] formats) {
		delete this.targets;

		this.targets = new .[formats.Count];
		formats.CopyTo(this.targets);

		return this;
	}

	public Self Primitive(Primitive primitive, PolygonMode polygonMode = .Fill) {
		this.primitive = primitive;
		this.polygonMode = polygonMode;

		return this;
	}

	public Self Cull(CullMode mode, FrontFace frontFace) {
		this.cullMode = mode;
		this.frontFace = frontFace;

		return this;
	}

	public Self Depth(bool depth, bool depthTest = true, bool depthWrite = true) {
		this.depth = depth;
		this.depthTest = depthTest;
		this.depthWrite = depthWrite;

		return this;
	}

	public Self Blend(bool blend) {
		this.blend = blend;

		return this;
	}

	public Self Blend(BlendMode color, BlendMode alpha) {
		this.blend = blend;
		this.colorBlend = color;
		this.alphaBlend = alpha;

		return this;
	}

	private Result<(VkPipeline, PipelineLayout)> CreateRaw() {
		// Shaders
		VkShaderModule vertModule = CreateShaderModule(vertShader, true).GetOrPropagate!();
		VkShaderModule fragModule = CreateShaderModule(fragShader, false).GetOrPropagate!();

		defer {
			vkDestroyShaderModule(Gfx.Device, vertModule, null);
			vkDestroyShaderModule(Gfx.Device, fragModule, null);
		}

		VkPipelineShaderStageCreateInfo[?] stages = .(
			.() {
				stage = .VK_SHADER_STAGE_VERTEX_BIT,
				module = vertModule,
				pName = "main"
			},
			.() {
				stage = .VK_SHADER_STAGE_FRAGMENT_BIT,
				module = fragModule,
				pName = "main"
			}
		);

		// Vertex input
		VkPipelineVertexInputStateCreateInfo vertexInputInfo = .() {
			vertexBindingDescriptionCount = 1,
			pVertexBindingDescriptions = &inputBinding
			vertexAttributeDescriptionCount = (.) inputAttributes.Count,
			pVertexAttributeDescriptions = inputAttributes.Ptr
		};

		// Input assembly
		VkPipelineInputAssemblyStateCreateInfo inputAssemblyInfo = .() {
			topology = primitive.Vk,
			primitiveRestartEnable = false
		};

		// Rasterization
		VkPipelineRasterizationStateCreateInfo rasterizationInfo = .() {
			depthClampEnable = false,
			rasterizerDiscardEnable = false,
			depthBiasEnable = false,
			polygonMode = polygonMode.Vk,
			lineWidth = 1,
			cullMode = cullMode.Vk,
			frontFace = frontFace.Vk
		};

		// Multisample
		VkPipelineMultisampleStateCreateInfo multisampleInfo = .() {
			sampleShadingEnable = false,
			rasterizationSamples = .VK_SAMPLE_COUNT_1_BIT
		};

		// Color blend attachment
		// TODO: ability to specify per-target blending
		VkPipelineColorBlendAttachmentState[] colorBlendAttachments = scope .[targets.Count];

		for (int i < targets.Count) {
			colorBlendAttachments[i] = .() {
				colorWriteMask = .VK_COLOR_COMPONENT_R_BIT | .VK_COLOR_COMPONENT_G_BIT | .VK_COLOR_COMPONENT_B_BIT | .VK_COLOR_COMPONENT_A_BIT,
				blendEnable = blend && targets[i].Vk == ImageFormat.BGRA.Vk,
				colorBlendOp = colorBlend.op.Vk,
				srcColorBlendFactor = colorBlend.src.Vk,
				dstColorBlendFactor = colorBlend.dst.Vk,
				alphaBlendOp = alphaBlend.op.Vk,
				srcAlphaBlendFactor = alphaBlend.src.Vk,
				dstAlphaBlendFactor = alphaBlend.dst.Vk
			};
		}

		VkPipelineColorBlendStateCreateInfo colorBlendInfo = .() {
			attachmentCount = (.) colorBlendAttachments.Count,
			pAttachments = colorBlendAttachments.Ptr,
			logicOpEnable = false
		};

		// Viewport
		VkPipelineViewportStateCreateInfo viewportInfo = .() {
			viewportCount = 1,
			scissorCount = 1
		};

		// Dynamic state
		VkDynamicState[?] dynamicStates = .(
			.VK_DYNAMIC_STATE_VIEWPORT,
			.VK_DYNAMIC_STATE_SCISSOR
		);

		VkPipelineDynamicStateCreateInfo dynamicStateInfo = .() {
			dynamicStateCount = dynamicStates.Count,
			pDynamicStates = &dynamicStates[0]
		};

		// Depth
		VkPipelineDepthStencilStateCreateInfo depthInfo = .() {
			depthTestEnable = depthTest,
			depthWriteEnable = depthWrite,
			depthCompareOp = .VK_COMPARE_OP_LESS
		};

		// Rendering
		VkFormat[] colorAttachments = scope .[targets.Count];
		for (let i < targets.Count) colorAttachments[i] = targets[i].Vk;

		VkPipelineRenderingCreateInfo renderingInfo = .() {
			colorAttachmentCount = (.) colorAttachments.Count,
			pColorAttachmentFormats = colorAttachments.Ptr,
			depthAttachmentFormat = depth ? ImageFormat.Depth.Vk : .VK_FORMAT_UNDEFINED
		};

		// Layout
		PipelineLayout layout = Gfx.PipelineLayouts.Get(sets, pushConstantsSize);

		// Graphics pipeline
		VkGraphicsPipelineCreateInfo info = .() {
			pNext = &renderingInfo,
			stageCount = stages.Count,
			pStages = &stages[0],
			pVertexInputState = &vertexInputInfo,
			pInputAssemblyState = &inputAssemblyInfo,
			pViewportState = &viewportInfo,
			pRasterizationState = &rasterizationInfo,
			pColorBlendState = &colorBlendInfo,
			pDynamicState = &dynamicStateInfo,
			pMultisampleState = &multisampleInfo,
			pDepthStencilState = depth ? &depthInfo : null,
			layout = layout,
			renderPass = .Null
		};

		VkPipeline pipeline = ?;
		VkResult result = vkCreateGraphicsPipelines(Gfx.Device, .Null, 1, &info, null, &pipeline);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan graphics pipeline: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_PIPELINE,
				objectHandle = pipeline,
				pObjectName = scope $"[PIPELINE] {name}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		return (pipeline, layout);
	}

	public Result<Pipeline> Create() {
		switch (CreateRaw()) {
		case .Ok(let val):	return new [Friend]Pipeline(this, val.0, val.1);
		case .Err:			return .Err;
		}
	}

	private int shaderModuleI = 0;

	private Result<VkShaderModule> CreateShaderModule(StringView path, bool vertex) {
		StringView data = path;
		StringView inputPath = path;

		ShaderReadResult* result_ = null;

		if (shaderPath) {
			StringView actualPath = scope:: $"{path}.{(vertex ? "vert" : "frag")}";

			result_ = manager.[Friend]readCallback(actualPath);
			//defer:: result.Dispose();         -- For some reason defer doesn't work here

			if (result_.contentLength == 0) {
				Log.Error("Failed to read shader file: {}", actualPath);
				result_.Dispose();
				return .Err;
			}

			data = .(result_.content, (.) result_.contentLength);
			inputPath = .(result_.sourceName, (.) result_.sourceNameLength);
		}

		Shaderc.Compiler compiler = scope .();
		Shaderc.CompileOptions options = scope .(manager.[Friend]options);

		options.AddMacroDefinition(vertex ? "VERTEX" : "FRAGMENT", "TRUE");
		shaderCompileCallback?.Invoke([Friend].(options));

		Shaderc.CompilationResult result = compiler.CompileIntoSpv(data, vertex ? .Vertex : .Fragment, inputPath, "main", options);
		defer delete result;

		if (result.Status != .Success) {
			Log.Error("Failed to compile shader: {}", result.ErrorMessage);
			result_?.Dispose();
			return .Err;
		}

		VkShaderModuleCreateInfo info = .() {
			codeSize = result.SpvLength * 4,
			pCode = result.Spv
		};

		VkShaderModule module = ?;
		VkResult vkResult = vkCreateShaderModule(Gfx.Device, &info, null, &module);
		
		if (vkResult != .VK_SUCCESS) {
			Log.Error("Failed to create shader module '{}': {}", path, vkResult);
			result_?.Dispose();
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_SHADER_MODULE,
				objectHandle = module,
				pObjectName = scope $"[SHADER] {shaderPath ? inputPath : shaderModuleI.ToString(.. scope .())}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		shaderModuleI++;
		
		result_?.Dispose();
		return module;
	}
}