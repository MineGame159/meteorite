using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti;

struct Descriptor {
	public DescriptorType type;
	public Data data;

	private this(DescriptorType type, Data data) {
		this.type = type;
		this.data = data;
	}

	public static Self Uniform(GpuBufferView view) {
		Data data = .();
		data.view = view;

		return .(.UniformBuffer, data);
	}

	public static Self Storage(GpuBufferView view) {
		Data data = .();
		data.view = view;

		return .(.StorageBuffer, data);
	}

	public static Self SampledImage(GpuImage image, VkImageLayout layout, Sampler sampler) {
		Data data = .();
		data.image = .(image, layout, sampler);
		
		return .(.SampledImage, data);
	}

	[Union]
	public struct Data {
		public GpuBufferView view;
		public SampledImageData image;
	}

	public struct SampledImageData : this(GpuImage image, VkImageLayout layout, Sampler sampler) {}
}

class DescriptorSet {
	private VkDescriptorPool pool;
	private VkDescriptorSet handle ~ vkFreeDescriptorSets(Gfx.Device, pool, 1, &_);

	private DescriptorSetLayout layout;
	private Descriptor[] descriptors ~ delete _;

	private bool invalid;

	private this(VkDescriptorPool pool, VkDescriptorSet handle, DescriptorSetLayout layout, Descriptor[] descriptors) {
		this.pool = pool;
		this.handle = handle;
		this.layout = layout;
		this.descriptors = new .[descriptors.Count];

		descriptors.CopyTo(this.descriptors);
	}

	public void Validate() {
		if (!invalid) return;

		vkFreeDescriptorSets(Gfx.Device, pool, 1, &handle);
		handle = Gfx.DescriptorSets.[Friend]CreateRaw(layout, descriptors);

		invalid = false;
	}
}

class DescriptorSetManager {
	private VkDescriptorPool pool ~ vkDestroyDescriptorPool(Gfx.Device, _, null);

	public this() {
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

	private Result<VkDescriptorSet> CreateRaw(DescriptorSetLayout layout, Descriptor[] descriptors) {
		var layout;

		VkDescriptorSetAllocateInfo info = .() {
			descriptorPool = pool,
			descriptorSetCount = 1,
			pSetLayouts = &layout
		};

		VkDescriptorSet set = ?;
		VkResult result = vkAllocateDescriptorSets(Gfx.Device, &info, &set);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan descriptor set: {}", result);
			return .Err;
		}

		VkWriteDescriptorSet[] writes = scope .[descriptors.Count];

		for (let i < descriptors.Count) {
			Descriptor desc = descriptors[i];

			writes[i] = .() {
				dstSet = set,
				dstBinding = (.) i,
				descriptorCount = 1
			};

			switch (desc.type) {
			case .UniformBuffer:
				VkDescriptorBufferInfo* bufferInfo = scope:: .() {
					buffer = desc.data.view.buffer.[Friend]handle,
					offset = desc.data.view.offset,
					range = desc.data.view.size
				};

				writes[i].descriptorType = DescriptorType.UniformBuffer.Vk;
				writes[i].pBufferInfo = bufferInfo;
			case .StorageBuffer:
				VkDescriptorBufferInfo* bufferInfo = scope:: .() {
					buffer = desc.data.view.buffer.[Friend]handle,
					offset = desc.data.view.offset,
					range = desc.data.view.size
				};

				writes[i].descriptorType = DescriptorType.StorageBuffer.Vk;
				writes[i].pBufferInfo = bufferInfo;
			case .SampledImage:
				VkDescriptorImageInfo* imageInfo = scope:: .() {
					imageView = desc.data.image.image.View,
					imageLayout = desc.data.image.layout,
					sampler = desc.data.image.sampler
				};

				writes[i].descriptorType = DescriptorType.SampledImage.Vk;
				writes[i].pImageInfo = imageInfo;
			}
		}

		vkUpdateDescriptorSets(Gfx.Device, (.) writes.Count, writes.Ptr, 0, null);

		return set;
	}

	public DescriptorSet Create(DescriptorSetLayout layout, params Descriptor[] descriptors) {
		DescriptorSet set = new [Friend].(pool, CreateRaw(layout, descriptors), layout, descriptors);

		for (let desc in descriptors) {
			if (desc.type == .SampledImage) {
				desc.data.image.image.[Friend]invalidatePointers.Add(&set.[Friend]invalid);
			}
		}

		return set;
	}
}