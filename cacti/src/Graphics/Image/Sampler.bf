using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

enum Filter {
	case Nearest,
		 Linear;

	public VkFilter Vk { get {
		return this == .Nearest ? .VK_FILTER_NEAREST : .VK_FILTER_LINEAR;
	} }
}

enum MipmapMode {
	case Nearest,
		 Linear;

	public VkSamplerMipmapMode Vk { get {
		return this == .Nearest ? .VK_SAMPLER_MIPMAP_MODE_NEAREST : .VK_SAMPLER_MIPMAP_MODE_LINEAR;
	} }
}

enum AddressMode {
	case Repeat,
		 MirroredRepeat,
		 ClampToEdge,
		 ClampToBorder,
		 MirroredClampToEdge;

	public VkSamplerAddressMode Vk { get {
		switch (this) {
		case .Repeat:				return .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		case .MirroredRepeat:		return .VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		case .ClampToEdge:			return .VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		case .ClampToBorder:		return .VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
		case .MirroredClampToEdge:	return .VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE;
		}
	} }
}

typealias Sampler = VkSampler;

class SamplerManager {
	private Dictionary<VkSamplerCreateInfo, Sampler> samplers = new .() ~ delete _;

	public int Count => samplers.Count;

	public ~this() {
		for (let sampler in samplers.Values) {
			vkDestroySampler(Gfx.Device, sampler, null);
		}
	}

	public Sampler Get(Filter mag, Filter min, MipmapMode mipmapMode = .Nearest, AddressMode addressModeU = .ClampToEdge, AddressMode addressModeV = .ClampToEdge, AddressMode addressModeW = .ClampToEdge, float minLod = 0, float maxLod = 0) {
		// Create sampler info
		VkSamplerCreateInfo info = .() {
			magFilter = mag.Vk,
			minFilter = min.Vk,
			mipmapMode = mipmapMode.Vk,
			addressModeU = addressModeU.Vk,
			addressModeV = addressModeV.Vk,
			addressModeW = addressModeW.Vk,
			minLod = minLod,
			maxLod = maxLod
		};

		// Check cache
		if (samplers.GetValue(info) case .Ok(let val)) return val;

		// Create new sampler
		VkSampler sampler = ?;
		vkCreateSampler(Gfx.Device, &info, null, &sampler);
		samplers[info] = sampler;

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_SAMPLER,
				objectHandle = sampler,
				pObjectName = scope $"[SAMPLER] {samplers.Count - 1}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		return sampler;
	}
}

namespace Bulkan {
	extension VkSamplerCreateInfo : IHashable {
		public int GetHashCode() {
			int hash = flags.Underlying;

			hash = Cacti.Utils.CombineHashCode(hash, magFilter.Underlying);
			hash = Cacti.Utils.CombineHashCode(hash, minFilter.Underlying);

			hash = Cacti.Utils.CombineHashCode(hash, mipmapMode.Underlying);
			hash = Cacti.Utils.CombineHashCode(hash, addressModeU.Underlying);
			hash = Cacti.Utils.CombineHashCode(hash, addressModeV.Underlying);
			hash = Cacti.Utils.CombineHashCode(hash, addressModeW.Underlying);

			hash = Cacti.Utils.CombineHashCode(hash, mipLodBias.GetHashCode());
			hash = Cacti.Utils.CombineHashCode(hash, anisotropyEnable.Value);
			hash = Cacti.Utils.CombineHashCode(hash, maxAnisotropy.GetHashCode());

			hash = Cacti.Utils.CombineHashCode(hash, compareEnable.Value);
			hash = Cacti.Utils.CombineHashCode(hash, compareOp.Underlying);

			hash = Cacti.Utils.CombineHashCode(hash, minLod.GetHashCode());
			hash = Cacti.Utils.CombineHashCode(hash, maxLod.GetHashCode());

			hash = Cacti.Utils.CombineHashCode(hash, borderColor.Underlying);
			hash = Cacti.Utils.CombineHashCode(hash, unnormalizedCoordinates.Value);

			return hash;
		}
	}
}