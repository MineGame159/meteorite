using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti;

typealias PipelineLayout = VkPipelineLayout;

class PipelineLayoutManager {
	private Dictionary<VkPipelineLayoutCreateInfo, PipelineLayout> layouts = new .() ~ delete _;

	public ~this() {
		for (let layout in layouts.Values) vkDestroyPipelineLayout(Gfx.Device, layout, null);
	}

	public PipelineLayout Get(DescriptorSetLayout[4] sets, uint32 pushConstantsSize) {
		List<VkDescriptorSetLayout> rawSets = scope .();

		for (let set in sets) {
			if (set != .Null) rawSets.Add(set);
		}

		VkPushConstantRange pushConstants = .() {
			size = pushConstantsSize,
			stageFlags = .VK_SHADER_STAGE_VERTEX_BIT | .VK_SHADER_STAGE_FRAGMENT_BIT
		};

		VkPipelineLayoutCreateInfo info = .() {
			setLayoutCount = (.) rawSets.Count,
			pSetLayouts = rawSets.Ptr,
			pushConstantRangeCount = pushConstantsSize > 0 ? 1 : 0,
			pPushConstantRanges = &pushConstants
		};

		if (layouts.GetValue(info) case .Ok(let val)) return val;

		VkPipelineLayout layout = ?;
		vkCreatePipelineLayout(Gfx.Device, &info, null, &layout);
		layouts[info] = layout;

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_PIPELINE_LAYOUT,
				objectHandle = layout,
				pObjectName = scope $"[PIPELINE_LAYOUT] {layouts.Count - 1}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		return layout;
	}
}

namespace Bulkan;

extension VkPipelineLayoutCreateInfo : IHashable {
	public int GetHashCode() {
		int hash = flags.Underlying;

		hash = Cacti.Utils.CombineHashCode(hash, setLayoutCount);
		for (int i < setLayoutCount) hash = Cacti.Utils.CombineHashCode(hash, pSetLayouts[i].GetHashCode());

		hash = Cacti.Utils.CombineHashCode(hash, pushConstantRangeCount);
		for (int i < pushConstantRangeCount) {
			let range = pPushConstantRanges[i];

			hash = Cacti.Utils.CombineHashCode(hash, range.stageFlags.Underlying);
			hash = Cacti.Utils.CombineHashCode(hash, range.offset.GetHashCode());
			hash = Cacti.Utils.CombineHashCode(hash, range.size.GetHashCode());
		}

		return hash;
	}
}