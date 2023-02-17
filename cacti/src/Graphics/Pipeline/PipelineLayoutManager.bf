using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class PipelineLayoutManager {
	private Dictionary<ShaderInfo, VkPipelineLayout> layouts = new .();

	public int Count => layouts.Count;

	public ~this() {
		for (let (info, layout) in layouts) {
			delete info;
			vkDestroyPipelineLayout(Gfx.Device, layout, null);
		}

		delete layouts;
	}

	[Tracy.Profile]
	public Result<VkPipelineLayout> Get(ShaderInfo info) {
		// Check cache
		VkPipelineLayout layout = ?;

		if (layouts.TryGetValue(info, out layout)) {
			return layout;
		}

		// Create layout
		VkDescriptorSetLayout* setLayouts = scope .[info.Sets.Count]*; // TODO: Should re-order sets if there are holes

		for (int i < info.Sets.Count) {
			setLayouts[i] = Gfx.DescriptorSetLayouts.Get(info.GetSet!(i));
		}

		VkPushConstantRange pushConstants = .() {
			size = info.PushConstantSize,
			stageFlags = .VK_SHADER_STAGE_VERTEX_BIT | .VK_SHADER_STAGE_FRAGMENT_BIT
		};

		VkPipelineLayoutCreateInfo createInfo = .() {
			setLayoutCount = (.) info.Sets.Count,
			pSetLayouts = setLayouts,
			pushConstantRangeCount = info.PushConstantSize > 0 ? 1 : 0,
			pPushConstantRanges = &pushConstants
		};

		VkResult result = vkCreatePipelineLayout(Gfx.Device, &createInfo, null, &layout);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan pipeline layout: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_PIPELINE_LAYOUT,
				objectHandle = layout,
				pObjectName = scope $"[PIPELINE_LAYOUT] {layouts.Count - 1}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		layouts[new .(info)] = layout;

		return layout;
	}
}