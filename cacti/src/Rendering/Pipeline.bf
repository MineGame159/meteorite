using System;
using System.IO;
using System.Threading;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using Shaderc;
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

struct Blending {
	public bool enabled;
	public BlendMode color, alpha;

	private this(bool enabled, BlendMode color, BlendMode alpha) {
		this.enabled = enabled;
		this.color = color;
		this.alpha = alpha;
	}

	public static Self Disabled() => .(false, default, default);

	public static Self Enabled(BlendMode color, BlendMode alpha) => .(true, color, alpha);

	public static Self Default() => .(true, .(.Add, .SrcAlpha, .OneMinusSrcAlpha), .(.Add, .One, .Zero));
}

struct PipelineTarget : this(ImageFormat format, Blending blending) {}

class PipelineInfo {
	public const int MAX_DESCRIPTOR_SETS = 4;
	public const int MAX_TARGETS = 4;

	private String name ~ delete _;
	
	private VertexFormat format = new .() ~ delete _;

	private String vertShader = new .() ~ delete _;
	private String fragShader = new .() ~ delete _;
	private RefCounted<ShaderPreProcessCallback> shaderCompileCallback ~ _?.Release();
	private bool shaderPath;

	private DescriptorSetLayout[MAX_DESCRIPTOR_SETS] sets;
	private uint32 pushConstantsSize;

	private Primitive primitive = .Traingles;
	private PolygonMode polygonMode = .Fill;

	private CullMode cullMode = .Back;
	private FrontFace frontFace = .Clockwise;

	private bool depthTarget, depthTest, depthWrite;

	private PipelineTarget[MAX_TARGETS] targets;
	private int targetCount;
	
	public this(StringView name) {
		this.name = new .(name);
	}

	public Self VertexFormat(VertexFormat format) {
		Debug.Assert(format != null);
		format.CopyTo(this.format);

		return this;
	}

	public Self Shader(StringView vertShader, StringView fragShader, ShaderPreProcessCallback compileCallback = null, bool path = true) {
		Debug.Assert(!vertShader.IsEmpty);
		Debug.Assert(!fragShader.IsEmpty);
		
		this.vertShader.Set(vertShader);
		this.fragShader.Set(fragShader);
		this.shaderCompileCallback = compileCallback != null ? .Attach(compileCallback) : null;
		this.shaderPath = path;

		return this;
	}

	public Self Sets(params DescriptorSetLayout[] sets) {
		Debug.Assert(sets.Count <= MAX_DESCRIPTOR_SETS);
		sets.CopyTo(this.sets);

		return this;
	}

	public Self PushConstants(uint32 size) {
		Debug.Assert(size > 0 && size <= 128);
		this.pushConstantsSize = size;
		
		return this;
	}

	public Self PushConstants<T>() => PushConstants((.) sizeof(T));

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

	public Self Depth(bool depthTarget, bool depthTest, bool depthWrite) {
		this.depthTarget = depthTarget;
		this.depthTest = depthTest;
		this.depthWrite = depthWrite;

		return this;
	}
	
	public Self Targets(params PipelineTarget[] targets) {
		Debug.Assert(targets.Count < MAX_TARGETS);

		targets.CopyTo(this.targets);
		targetCount = targets.Count;
		
		return this;
	}

	public void CopyTo(PipelineInfo info) {
		info.name.Set(name);

		format.CopyTo(info.format);

		info.vertShader.Set(vertShader);
		info.fragShader.Set(fragShader);
		info.shaderCompileCallback = shaderCompileCallback != null ? shaderCompileCallback..AddRef() : null;
		info.shaderPath = shaderPath;

		info.sets = sets;
		info.pushConstantsSize = pushConstantsSize;

		info.primitive = primitive;
		info.polygonMode = polygonMode;

		info.cullMode = cullMode;
		info.frontFace = frontFace;

		info.depthTest = depthTest;
		info.depthWrite = depthWrite;
		
		info.targets = targets;
		info.targetCount = targetCount;
	}

	public mixin VkVertexInput() {
		VkVertexInputBindingDescription inputBinding = .() {
			binding = 0,
			stride = (.) format.size,
			inputRate = .VK_VERTEX_INPUT_RATE_VERTEX
		};

		VkVertexInputAttributeDescription[] inputAttributes = scope:mixin .[format.attributes.Count];
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

		VkPipelineVertexInputStateCreateInfo() {
			vertexBindingDescriptionCount = 1,
			pVertexBindingDescriptions = &inputBinding
			vertexAttributeDescriptionCount = (.) inputAttributes.Count,
			pVertexAttributeDescriptions = inputAttributes.Ptr
		}
	}

	public mixin VkInputAssembly() {
		VkPipelineInputAssemblyStateCreateInfo() {
			topology = primitive.Vk,
			primitiveRestartEnable = false
		}
	}

	public mixin VkRasterization() {
		VkPipelineRasterizationStateCreateInfo() {
			depthClampEnable = false,
			rasterizerDiscardEnable = false,
			depthBiasEnable = false,
			polygonMode = polygonMode.Vk,
			lineWidth = 1,
			cullMode = cullMode.Vk,
			frontFace = frontFace.Vk
		}
	}

	public mixin VkMultisample() {
		VkPipelineMultisampleStateCreateInfo() {
			sampleShadingEnable = false,
			rasterizationSamples = .VK_SAMPLE_COUNT_1_BIT
		}
	}
	
	public mixin VkBlendState() {
		VkPipelineColorBlendAttachmentState[] colorBlendAttachments = scope:mixin .[targetCount];
		
		for (int i < targetCount) {
			Blending blending = targets[i].blending;

			colorBlendAttachments[i] = .() {
				colorWriteMask = .VK_COLOR_COMPONENT_R_BIT | .VK_COLOR_COMPONENT_G_BIT | .VK_COLOR_COMPONENT_B_BIT | .VK_COLOR_COMPONENT_A_BIT,
				blendEnable = blending.enabled,
				colorBlendOp = blending.color.op.Vk,
				srcColorBlendFactor = blending.color.src.Vk,
				dstColorBlendFactor = blending.color.dst.Vk,
				alphaBlendOp = blending.alpha.op.Vk,
				srcAlphaBlendFactor = blending.alpha.src.Vk,
				dstAlphaBlendFactor = blending.alpha.dst.Vk
			};
		}

		VkPipelineColorBlendStateCreateInfo() {
			attachmentCount = (.) colorBlendAttachments.Count,
			pAttachments = colorBlendAttachments.Ptr,
			logicOpEnable = false
		}
	}

	public mixin VkViewport() {
		VkPipelineViewportStateCreateInfo() {
			viewportCount = 1,
			scissorCount = 1
		}
	}

	public mixin VkDynamicState() {
		VkDynamicState[?] dynamicStates = .(
			.VK_DYNAMIC_STATE_VIEWPORT,
			.VK_DYNAMIC_STATE_SCISSOR
		);

		VkPipelineDynamicStateCreateInfo() {
			dynamicStateCount = dynamicStates.Count,
			pDynamicStates = &dynamicStates[0]
		}
	}

	public mixin VkDepth() {
		VkPipelineDepthStencilStateCreateInfo() {
			depthTestEnable = depthTest,
			depthWriteEnable = depthWrite,
			depthCompareOp = .VK_COMPARE_OP_LESS
		}
	}

	public mixin VkRendering() {
		VkFormat[] colorAttachments = scope:mixin .[targetCount];
		for (let i < targetCount) colorAttachments[i] = targets[i].format.Vk;
		
		VkPipelineRenderingCreateInfo() {
			colorAttachmentCount = (.) colorAttachments.Count,
			pColorAttachmentFormats = colorAttachments.Ptr,
			depthAttachmentFormat = depthTarget ? ImageFormat.Depth.Vk : .VK_FORMAT_UNDEFINED
		}
	}

	public VkShaderModule VkShaderModule(bool vertex) {
		StringView path = vertex ? vertShader : fragShader;

		StringView data = path;
		StringView inputPath = path;

		ShaderReadResult* result_ = null;

		if (shaderPath) {
			StringView actualPath = scope:: $"{path}.{(vertex ? "vert" : "frag")}";

			result_ = Gfx.Pipelines.[Friend]readCallback(actualPath);
			//defer:: result.Dispose();         -- For some reason defer doesn't work here

			if (result_.contentLength == 0) {
				Log.Error("Failed to read shader file: {}", actualPath);
				result_.Dispose();
				return VkShaderModule.Null;
			}

			data = .(result_.content, (.) result_.contentLength);
			inputPath = .(result_.sourceName, (.) result_.sourceNameLength);
		}

		Shaderc.Compiler compiler = scope .();
		Shaderc.CompileOptions options = scope .(Gfx.Pipelines.[Friend]options);

		options.AddMacroDefinition(vertex ? "VERTEX" : "FRAGMENT", "TRUE");
		shaderCompileCallback?.Value.Invoke([Friend].(options));

		Shaderc.CompilationResult result = compiler.CompileIntoSpv(data, vertex ? .Vertex : .Fragment, inputPath, "main", options);
		defer delete result;

		if (result.Status != .Success) {
			Log.Error("Failed to compile shader: {}", result.ErrorMessage);
			result_?.Dispose();
			return VkShaderModule.Null;
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
			return VkShaderModule.Null;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_SHADER_MODULE,
				objectHandle = module,
				pObjectName = scope $"[SHADER] {(shaderPath ? inputPath : "<inline>")}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}
		
		result_?.Dispose();
		return module;
	}
}

class Pipeline : IRefCounted {
	public PipelineInfo info = new .("") ~ delete _;

	private VkPipeline handle ~ vkDestroyPipeline(Gfx.Device, _, null);
	private PipelineLayout layout;

	private int refCount = 1;
	private bool valid = true;

	private this(PipelineInfo info, VkPipeline handle, PipelineLayout layout) {
		info.CopyTo(this.info);

		this.handle = handle;
		this.layout = layout;
	}

	public ~this() {
		Debug.Assert(refCount == 0);
		
		Gfx.Pipelines.[Friend]Remove(info);
	}

	public VkPipeline Vk => handle;
	public PipelineLayout Layout => layout;

	public Result<void> Reload() {
		VkPipeline oldHandle = handle;
		Gfx.RunOnNewFrame(new () => vkDestroyPipeline(Gfx.Device, oldHandle, null));

		(handle, layout) = Gfx.Pipelines.[Friend]Create(info).GetOrPropagate!();
		
		return .Ok;
	}

	public void AddRef() {
		Interlocked.Increment(ref refCount);
	}

	public void Release() {
		Debug.Assert(refCount > 0);

		Interlocked.Decrement(ref refCount);
		if (refCount == 0) Delete(true);
	}

	private void ForceDelete() {
		refCount = 0;
		Delete(false);
	}

	private void Delete(bool useDeleteQueue) {
		if (!valid) return;
		valid = false;

		if (useDeleteQueue) {
			Gfx.Pipelines.[Friend]deleteQueue.Add(this);
		}
		else {
			delete this;
		}
	}
}

class PipelineManager {
	private VkPipelineCache vkCache ~ vkDestroyPipelineCache(Gfx.Device, _, null);

	private Dictionary<PipelineInfo, Pipeline> cache = new .() ~ delete _;

	private Shaderc.CompileOptions options = new .() ~ delete _;
	private ShaderReadCallback readCallback ~ delete _;

	private List<Pipeline> deleteQueue = new .() ~ delete _;

	public this() {
		VkPipelineCacheCreateInfo info = .();
		vkCreatePipelineCache(Gfx.Device, &info, null, &vkCache);

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

	public ~this() {
		deleteQueue.ClearAndDeleteItems();

		for (let pipeline in cache.Values) {
			pipeline.[Friend]ForceDelete();
		}
	}

	public void NewFrame() {
		deleteQueue.ClearAndDeleteItems();
	}

	public void SetReadCallback(ShaderReadCallback callback) {
		delete this.readCallback;
		this.readCallback = callback;
	}
	
	public Result<Pipeline> Get(PipelineInfo info) {
		// Check the cache
		if (cache.GetValue(info) case .Ok(let pipeline)) return pipeline..AddRef();

		// Create new pipeline
		let (handle, layout) = Create(info).GetOrPropagate!();

		Pipeline pipeline = new [Friend].(info, handle, layout);
		return cache[pipeline.info] = pipeline;
	}

	private void Remove(PipelineInfo info) {
		cache.Remove(info);
	}

	private Result<(VkPipeline, PipelineLayout)> Create(PipelineInfo info) {
		VkShaderModule vertModule = info.VkShaderModule(true);
		if (vertModule == .Null) return .Err;

		VkShaderModule fragModule = info.VkShaderModule(false);
		if (fragModule == .Null) {
			vkDestroyShaderModule(Gfx.Device, vertModule, null);
			return .Err;
		}

		defer {
			vkDestroyShaderModule(Gfx.Device, vertModule, null);
			vkDestroyShaderModule(Gfx.Device, fragModule, null);
		}

		PipelineLayout layout = Gfx.PipelineLayouts.Get(info.[Friend]sets, info.[Friend]pushConstantsSize);

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

		VkGraphicsPipelineCreateInfo createInfo = .() {
			pNext = &info.VkRendering!(),
			stageCount = stages.Count,
			pStages = &stages[0],
			pVertexInputState = &info.VkVertexInput!(),
			pInputAssemblyState = &info.VkInputAssembly!(),
			pViewportState = &info.VkViewport!(),
			pRasterizationState = &info.VkRasterization!(),
			pColorBlendState = &info.VkBlendState!(),
			pDynamicState = &info.VkDynamicState!(),
			pMultisampleState = &info.VkMultisample!(),
			pDepthStencilState = info.[Friend]depthTarget ? &info.VkDepth!() : null,
			layout = layout,
			renderPass = .Null
		};

		VkPipeline pipeline = ?;
		VkResult result = vkCreateGraphicsPipelines(Gfx.Device, vkCache, 1, &createInfo, null, &pipeline);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan graphics pipeline: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_PIPELINE,
				objectHandle = pipeline,
				pObjectName = scope $"[PIPELINE] {info.[Friend]name}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		return (pipeline, layout);
	}
}

typealias ShaderReadResult = Shaderc.IncludeResult;
typealias ShaderReadCallback = delegate ShaderReadResult*(StringView path);

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