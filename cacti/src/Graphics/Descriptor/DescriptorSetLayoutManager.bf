using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class DescriptorSetLayoutManager {
	private Dictionary<Info, DescriptorSetLayout> layouts = new .() ~ delete _;

	public int Count => layouts.Count;

	public ~this() {
		for (let pair in layouts) {
			pair.key.Dispose();
			vkDestroyDescriptorSetLayout(Gfx.Device, pair.value, null);
		}
	}

	[Tracy.Profile]
	public Result<DescriptorSetLayout> Get(Span<DescriptorType> types) {
		// Return null if types is empty
		if (types.IsEmpty) return DescriptorSetLayout.Null;

		// Get info
		Info info = .Point(types);

		// Check cache
		if (layouts.GetValue(info) case .Ok(let val)) return val;

		// Create new layout
		VkDescriptorSetLayoutBinding[] bindings = scope .[types.Length];

		for (let i < types.Length) {
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

		layouts[.Copy(info)] = layout;

		return layout;
	}

	struct Info : IEquatable<Self>, IHashable, IDisposable {
		private DescriptorType* types;
		private int count;

		private int hash;
		private bool copied;

		private this(DescriptorType* types, int count, bool copied) {
			this.types = types;
			this.count = count;

			this.hash = count;
			this.copied = copied;

			for (int i < count) {
				this.hash = Utils.CombineHashCode(this.hash, types[i].Underlying);
			}
		}

		public static Self Point(Span<DescriptorType> types) => .(types.Ptr, types.Length, false);

		public static Self Copy(Info info) {
			DescriptorType* copy = new .[info.count]*;
			Internal.MemCpy(copy, info.types, sizeof(DescriptorType) * info.count);

			return .(copy, info.count, true);
		}

		public bool Equals(Self other) {
			if (other.count != other.count) return false;

			for (let i < count) {
				if (types[i] != other.types[i]) return false;
			}

			return true;
		}

		public int GetHashCode() => hash;
		
		public void Dispose() {
			if (copied) delete types;
		}

		[Commutable]
		public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	}
}