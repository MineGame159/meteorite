using System;
using System.Diagnostics;

using Bulkan;

namespace Cacti.Graphics;

class PipelineInfo {
	// Fields

	public const int MAX_DESCRIPTOR_SETS = 4;
	public const int MAX_TARGETS = 4;

	private String name ~ delete _;

	private VertexFormat format = new .() ~ delete _;

	private ShaderSource vertexShaderSource ~ delete _;
	private ShaderSource fragmentShaderSource ~ delete _;
	private RefCounted<ShaderPreProcessCallback> shaderPreprocessCallback ~ _?.Release();

	private Primitive primitive = .Traingles;
	private PolygonMode polygonMode = .Fill;

	private CullMode cullMode = .Back;
	private FrontFace frontFace = .Clockwise;

	private bool depthTarget, depthTest, depthWrite;

	private PipelineTarget[MAX_TARGETS] targets;
	private int targetCount;

	// Constructors / Destructors

	public this(StringView name) {
		this.name = new .(name);
	}

	// Builder methods

	public Self VertexFormat(VertexFormat format) {
		Debug.Assert(format != null);
		format.CopyTo(this.format);

		return this;
	}

	public Self Shader(ShaderSource vertexShaderSource, ShaderSource fragmentShaderSource, ShaderPreProcessCallback preprocessCallback = null) {
		Debug.Assert(vertexShaderSource != null);
		Debug.Assert(fragmentShaderSource != null);
	
		this.vertexShaderSource = vertexShaderSource;
		this.fragmentShaderSource = fragmentShaderSource;
		this.shaderPreprocessCallback = preprocessCallback != null ? .Attach(preprocessCallback) : null;

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

		info.vertexShaderSource = vertexShaderSource.Copy();
		info.fragmentShaderSource = fragmentShaderSource.Copy();
		info.shaderPreprocessCallback = shaderPreprocessCallback != null ? shaderPreprocessCallback..AddRef() : null;

		info.primitive = primitive;
		info.polygonMode = polygonMode;
		
		info.cullMode = cullMode;
		info.frontFace = frontFace;

		info.depthTarget = depthTarget;
		info.depthTest = depthTest;
		info.depthWrite = depthWrite;
	
		info.targets = targets;
		info.targetCount = targetCount;
	}

	// Vulkan mixins

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
			depthCompareOp = .VK_COMPARE_OP_LESS_OR_EQUAL
		}
	}
}