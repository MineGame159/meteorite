using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class DescriptorSetManager {
	private VkDescriptorPool pool ~ vkDestroyDescriptorPool(Gfx.Device, _, null);

	private Dictionary<Info, VkDescriptorSet> sets = new .() ~ delete _;

	public this() {
		// Create pool
		VkDescriptorPoolSize[Enum.GetCount<DescriptorType>()] sizes = .();
		for (int i < sizes.Count) {
			sizes[i] = .() {
				type = ((DescriptorType) i).Vk,
				descriptorCount = 1000
			};
		}

		VkDescriptorPoolCreateInfo info = .() {
			flags = .VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
			maxSets = 1000,
			poolSizeCount = sizes.Count,
			pPoolSizes = &sizes[0]
		};

		VkResult result = vkCreateDescriptorPool(Gfx.Device, &info, null, &pool);
		if (result != .VK_SUCCESS) Log.Error("Failed to create Vulkan descriptor pool: {}", result);
	}

	public void Destroy() {
		for (var (info, set) in sets) {
			info.Dispose();
			vkFreeDescriptorSets(Gfx.Device, pool, 1, &set);
		}

		sets.Clear();
	}

	[Tracy.Profile]
	public void NewFrame() {
		// Destroy descriptor sets pointing to resources that are about to be deleted
		for (var (info, set) in sets) {
			// Check if the set contains a resource that has only one reference
			bool destroy = false;

			for (let descriptor in info) {
				switch (descriptor.Type) {
				case .UniformBuffer, .StorageBuffer:
					destroy = descriptor.Buffer.buffer.NoReferences;

				case .SampledImage:
					destroy = descriptor.Image.image.NoReferences;
				}

				if (destroy) {
					break;
				}
			}

			// Destroy set
			if (destroy) {
				info.Dispose();
				vkFreeDescriptorSets(Gfx.Device, pool, 1, &set);

				@info.Remove();
			}
		}
	}
	
	[Tracy.Profile]
	public Result<VkDescriptorSet> Get(Descriptor[] descriptors) {
		// Check cache
		Info info = .Point(descriptors);
		VkDescriptorSet set;

		if (sets.TryGetValue(info, out set)) {
			return set;
		}

		// Create set
		DescriptorType[] types = scope .[descriptors.Count];

		for (int i < descriptors.Count) {
			types[i] = descriptors[i].Type;
		}

		DescriptorSetLayout layout = Gfx.DescriptorSetLayouts.Get(types);

		VkDescriptorSetAllocateInfo createInfo = .() {
			descriptorPool = pool,
			descriptorSetCount = 1,
			pSetLayouts = &layout
		};

		VkResult result = vkAllocateDescriptorSets(Gfx.Device, &createInfo, &set);

		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan descriptor set: {}", result);
			return .Err;
		}

		// Write descriptors to set
		VkWriteDescriptorSet[] writes = scope .[descriptors.Count];

		for (let i < descriptors.Count) {
			Descriptor desc = descriptors[i];

			writes[i] = .() {
				dstSet = set,
				dstBinding = (.) i,
				descriptorCount = 1
			};

			switch (desc.Type) {
			case .UniformBuffer:
				VkDescriptorBufferInfo* bufferInfo = scope:: .() {
					buffer = desc.Buffer.buffer.[Friend]handle,
					offset = desc.Buffer.offset,
					range = desc.Buffer.size
				};

				writes[i].descriptorType = DescriptorType.UniformBuffer.Vk;
				writes[i].pBufferInfo = bufferInfo;

				desc.Buffer.buffer.AddWeakRef();

			case .StorageBuffer:
				VkDescriptorBufferInfo* bufferInfo = scope:: .() {
					buffer = desc.Buffer.buffer.[Friend]handle,
					offset = desc.Buffer.offset,
					range = desc.Buffer.size
				};

				writes[i].descriptorType = DescriptorType.StorageBuffer.Vk;
				writes[i].pBufferInfo = bufferInfo;

				desc.Buffer.buffer.AddWeakRef();

			case .SampledImage:
				VkDescriptorImageInfo* imageInfo = scope:: .() {
					imageView = desc.Image.image.GetView().GetOrPropagate!().Vk,
					imageLayout = .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
					sampler = desc.Image.sampler
				};

				writes[i].descriptorType = DescriptorType.SampledImage.Vk;
				writes[i].pImageInfo = imageInfo;

				desc.Image.image.AddWeakRef();
			}
		}

		vkUpdateDescriptorSets(Gfx.Device, (.) writes.Count, writes.Ptr, 0, null);

		// Add to cache and return
		sets[.Copy(info)] = set;

		return set;
	}

	struct Info : IEnumerable<Descriptor>, IEquatable<Self>, IHashable, IDisposable {
		private Span<Descriptor> descriptors;

		private int hash;
		private bool copied;

		private this(Span<Descriptor> descriptors, bool copied) {
			this.descriptors = descriptors;

			this.hash = descriptors.GetCombinedHashCode();
			this.copied = copied;
		}

		public static Self Point(Span<Descriptor> descriptors) => .(descriptors, false);
		
		public static Self Copy(Self info) => .(info.descriptors.Copy(), true);

		public Span<Descriptor>.Enumerator GetEnumerator() => descriptors.GetEnumerator();

		public bool Equals(Self other) {
			if (descriptors.Length != other.descriptors.Length) return false;

			for (int i < descriptors.Length) {
				if (descriptors[i] != other.descriptors[i]) return false;
			}

			return true;
		}

		public int GetHashCode() => hash;

		public void Dispose() {
			for (let descriptor in descriptors) {
				switch (descriptor.Type) {
				case .UniformBuffer, .StorageBuffer:
					descriptor.Buffer.buffer.ReleaseWeak();

				case .SampledImage:
					descriptor.Image.image.ReleaseWeak();
				}
			}

			if (copied) {
				delete descriptors.Ptr;
			}
		}

		[Commutable]
		public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	}
}