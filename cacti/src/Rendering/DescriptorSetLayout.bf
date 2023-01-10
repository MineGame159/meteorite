using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti;

enum DescriptorType {
	case UniformBuffer,
		 StorageBuffer,
		 SampledImage;

	public VkDescriptorType Vk { get {
		switch (this) {
		case .UniformBuffer:	return .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
		case .StorageBuffer:	return .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
		case .SampledImage:		return .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
		}
	} }
}

typealias DescriptorSetLayout = VkDescriptorSetLayout;

class DescriptorSetLayoutManager {
	private Dictionary<Info, DescriptorSetLayout> layouts = new .() ~ delete _;

	public ~this() {
		for (let pair in layouts) {
			pair.key.Dispose();
			vkDestroyDescriptorSetLayout(Gfx.Device, pair.value, null);
		}
	}

	// TODO: Figure out some better way to retrieve the layout from the cache without copying the types array
	public Result<DescriptorSetLayout> Get(params DescriptorType[] types) {
		// Check cache
		if (layouts.GetValue(.(types, false)) case .Ok(let val)) return val;

		// Create new layout
		VkDescriptorSetLayoutBinding[] bindings = scope .[types.Count];

		for (let i < types.Count) {
			bindings[i] = .() {
				binding = (.) i,
				descriptorType = types[i].Vk
				descriptorCount = 1,
				stageFlags = .VK_SHADER_STAGE_VERTEX_BIT | .VK_SHADER_STAGE_FRAGMENT_BIT
			};
		}

		VkDescriptorSetLayoutCreateInfo createInfo = .() {
			bindingCount = (.) bindings.Count,
			pBindings = bindings.Ptr
		};

		VkDescriptorSetLayout layout = ?;
		VkResult result = vkCreateDescriptorSetLayout(Gfx.Device, &createInfo, null, &layout);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan descriptor set: {}", result);
			return .Err;
		}

		layouts[.(types, true)] = layout;
		return layout;
	}

	struct Info : IDisposable, IEquatable<Self>, IHashable {
		public DescriptorType[] types;
		private bool owned;

		public this(DescriptorType[] types, bool owned) {
			this.types = owned ? new .[types.Count] : types;
			this.owned = owned;

			if (owned) types.CopyTo(this.types);
		}

		public void Dispose() {
			if (owned) delete types;
		}

		public bool Equals(Info val) {
			if (types.Count != val.types.Count) return false;

			for (let i < types.Count) {
				if (types[i] != val.types[i]) return false;
			}

			return true;
		}

		public int GetHashCode() {
			int hash = types.Count;

			for (let type in types) {
				hash = Utils.CombineHashCode(hash, type.Underlying);
			}

			return hash;
		}

		public static bool operator==(Info lhs, Info rhs) => lhs.Equals(rhs);
	}
}