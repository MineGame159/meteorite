using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class PipelineManager {
	private VkPipelineCache cache ~ vkDestroyPipelineCache(Gfx.Device, _, null);

	private List<Pipeline> pipelines = new .() ~ delete _;

	public int Count => pipelines.Count;

	public this() {
		VkPipelineCacheCreateInfo info = .();

		VkResult result = vkCreatePipelineCache(Gfx.Device, &info, null, &cache);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan pipeline cache: {}", result);
		}
	}

	[Tracy.Profile]
	public Result<Pipeline> Create(PipelineInfo info) {
		PipelineInfo copy = new .("");
		info.CopyTo(copy);

		Shader vertexShader = Gfx.Shaders.Create(.Vertex, copy.[Friend]vertexShaderSource, copy.[Friend]shaderPreprocessCallback).GetOrPropagate!();
		Shader fragmentShader = Gfx.Shaders.Create(.Fragment, copy.[Friend]fragmentShaderSource, copy.[Friend]shaderPreprocessCallback).GetOrPropagate!();

		Pipeline pipeline = new [Friend].(copy, vertexShader, fragmentShader);
		pipelines.Add(pipeline);

		if (pipeline.[Friend]Init() == .Err) {
			pipeline.Release();
		}

		return pipeline;
	}
}