using System;
using System.Threading;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class Pipeline : DoubleRefCounted {
	// Fields

	// TODO: Vulkan doesn't need a separate pipeline for every render pass, the pipeline can be reused between passes as long as the passes are compatible
	private VkPipelineLayout layout;
	private Dictionary<RenderPass, VkPipeline> handles = new .();

	private PipelineInfo info ~ delete _;

	private Shader vertexShader;
	private Shader fragmentShader;

	private append ShaderInfo shaderInfo = .();

	private bool valid = true;

	// Properties

	public VkPipelineLayout Layout => layout;

	public PipelineInfo Info => info;

	// Constructors / Destructors

	private this(PipelineInfo info, Shader vertexShader, Shader fragmentShader) {
		this.info = info;
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;

		vertexShader.AddWeakRef();
		fragmentShader.AddWeakRef();
	}

	public ~this() {
		delete handles;

		vertexShader.ReleaseWeak();
		fragmentShader.ReleaseWeak();

		Gfx.Pipelines.[Friend]pipelines.Remove(this);
	}

	private Result<void> Init() {
		shaderInfo.Clear();
		shaderInfo.Merge(vertexShader.Info).GetOrPropagate!();
		shaderInfo.Merge(fragmentShader.Info).GetOrPropagate!();

		layout = Gfx.PipelineLayouts.Get(shaderInfo).GetOrPropagate!();
										
		return .Ok;
	}

	private void DestroyHandles() {
		for (let handle in handles.Values) {
			vkDestroyPipeline(Gfx.Device, handle, null);
		}

		handles.Clear();
	}

	// Reference counting

	protected override void Delete() {
		if (valid) {
			AddWeakRef();
			Gfx.ReleaseNextFrame(this);

			valid = false;
		}
		else {
			delete this;
		}
	}

	// Pipeline

	public Result<VkPipeline> GetVk(RenderPass pass) {
		// Check cache
		VkPipeline handle;

		if (handles.TryGetValue(pass, out handle)) {
			return handle;
		}

		// Create handle
		VkPipelineShaderStageCreateInfo[?] stages = .(
			.() {
				stage = .VK_SHADER_STAGE_VERTEX_BIT,
				module = vertexShader.Vk,
				pName = "main"
			},
			.() {
				stage = .VK_SHADER_STAGE_FRAGMENT_BIT,
				module = fragmentShader.Vk,
				pName = "main"
			}
		);

		VkGraphicsPipelineCreateInfo createInfo = .() {
			renderPass = pass.Vk,
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
			layout = layout
		};

		VkResult result = vkCreateGraphicsPipelines(Gfx.Device, Gfx.Pipelines.[Friend]cache, 1, &createInfo, null, &handle);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan pipeline: {}", result);
			return .Err;
		}

		handles[pass] = handle;

		return handle;
	}

	public Result<void> Reload() {
		// Reload shaders
		vertexShader.ReleaseWeak();
		fragmentShader.ReleaseWeak();

		vertexShader = Gfx.Shaders.Get(.Vertex, info.[Friend]vertexShaderSource, info.[Friend]shaderPreprocessCallback).GetOrPropagate!()..AddWeakRef();
		fragmentShader = Gfx.Shaders.Get(.Fragment, info.[Friend]fragmentShaderSource, info.[Friend]shaderPreprocessCallback).GetOrPropagate!()..AddWeakRef();

		Init();
		
		// Destroy handles
		Gfx.RunOnNewFrame(new => DestroyHandles);

		return .Ok;
	}

	public Result<void> ReloadIfOutdatedShaders() {
		if (vertexShader.NoReferences || fragmentShader.NoReferences) {
			return Reload();
		}

		return .Ok;
	}
}