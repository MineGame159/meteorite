using System;
using System.Collections;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti.Graphics;

class GpuImageManager {
	private List<GpuImage> images = new .() ~ delete _;

	public int Count => images.Count;

	[Tracy.Profile]
	public Result<GpuImage> Create(StringView name, ImageFormat format, ImageUsage usage, Vec2i size, int mipLevels = 1) {
		VkImageCreateInfo info = .() {
			imageType = .VK_IMAGE_TYPE_2D,
			format = format.Vk,
			extent = .() {
				width = (.) size.x,
				height = (.) size.y,
				depth = 1
			},
			mipLevels = (.) mipLevels,
			arrayLayers = 1,
			samples = .VK_SAMPLE_COUNT_1_BIT,
			tiling = .VK_IMAGE_TILING_OPTIMAL,
			usage = usage.Vk | .VK_IMAGE_USAGE_SAMPLED_BIT,
			initialLayout = .VK_IMAGE_LAYOUT_UNDEFINED
		};

		VmaAllocationCreateInfo allocationInfo = .() {
			usage = .VMA_MEMORY_USAGE_AUTO,
			flags = .VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT
		};

		VkImage handle = ?;
		VmaAllocation allocation = ?;
		VkResult result = vmaCreateImage(Gfx.VmaAllocator, &info, &allocationInfo, &handle, &allocation, null);

		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan image: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_IMAGE,
				objectHandle = handle,
				pObjectName = scope $"[IMAGE] {name}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		// Return
		GpuImage image = new [Friend].(handle, allocation, false, name, format, usage, size, mipLevels);
		images.Add(image);

		return image;
	}

	public Result<void> Resize(ref GpuImage image, Vec2i size) {
		// Return if the image is already the same size or if it is null
		if (image == null || image.Size == size) return .Ok;

		// Release the old image
		image.Release();

		// Create new image
		switch (Create(image.Name, image.Format, image.Usage, size, image.MipLevels)) {
		case .Ok(let val):
			image = val;
			return .Ok;
		case .Err:
			return .Err;
		}
	}
}