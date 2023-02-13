using System;

using Bulkan;

namespace Cacti.Graphics;

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

struct Descriptor : IHashable {
	private DescriptorType type;
	private Data data;

	public DescriptorType Type => type;

	public GpuBufferView Buffer => data.view;
	public SampledImageData Image => data.image;

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

	public static Self SampledImage(GpuImage image, Sampler sampler) {
		Data data = .();
		data.image = .(image, sampler);
		
		return .(.SampledImage, data);
	}

	public int GetHashCode() {
		int hash = type.Underlying;

		switch (type) {
		case .UniformBuffer:
			Utils.CombineHashCode(ref hash, 1);
			Utils.CombineHashCode(ref hash, data.view);

		case .StorageBuffer:
			Utils.CombineHashCode(ref hash, 2);
			Utils.CombineHashCode(ref hash, data.view);

		case .SampledImage:
			Utils.CombineHashCode(ref hash, 3);
			Utils.CombineHashCode(ref hash, data.image);
		}

		return hash;
	}

	[Union]
	public struct Data {
		public GpuBufferView view;
		public SampledImageData image;
	}

	public struct SampledImageData : this(GpuImage image, Sampler sampler), IHashable {
		public int GetHashCode() => Utils.CombineHashCode(image.GetHashCode(), (.) sampler.Handle);
	}
}