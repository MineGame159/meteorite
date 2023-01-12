using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti;

class Swapchain {
	private VkSwapchainKHR handle = .Null ~ vkDestroySwapchainKHR(Gfx.Device, _, null);
	private List<GpuImage> images = new .() ~ DeleteContainerAndItems!(_);

	public uint32 index;

	public Result<void> Recreate(Vec2i size) {
		ImageFormat format = .BGRA;

		if (handle != .Null) {
			vkDeviceWaitIdle(Gfx.Device);
			vkDestroySwapchainKHR(Gfx.Device, handle, null);
		}

		VkSurfaceCapabilitiesKHR capabilities = ?;
		vkGetPhysicalDeviceSurfaceCapabilitiesKHR(Gfx.PhysicalDevice, Gfx.Surface, &capabilities);

		uint32 imageCount = capabilities.minImageCount + 1;
		if (capabilities.maxImageCount > 0 && imageCount > capabilities.maxImageCount) imageCount = capabilities.maxImageCount;

		VkSwapchainCreateInfoKHR info = .() {
			surface = Gfx.Surface,
			minImageCount = imageCount,
			imageFormat = format.Vk,
			imageColorSpace = .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
			imageExtent = capabilities.currentExtent,
			imageArrayLayers = 1,
			imageUsage = .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
			imageSharingMode = .VK_SHARING_MODE_EXCLUSIVE,
			preTransform = capabilities.currentTransform,
			compositeAlpha = .VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
			presentMode = .VK_PRESENT_MODE_FIFO_KHR,
			clipped = true
		};

		if (capabilities.currentExtent.width == uint32.MaxValue) {
			info.imageExtent = .(
				(.) Math.Clamp(size.x, capabilities.minImageExtent.width, capabilities.maxImageExtent.width),
				(.) Math.Clamp(size.y, capabilities.minImageExtent.height, capabilities.maxImageExtent.height)
			);
		}

		Gfx.QueueFamilyIndices indices = Gfx.FindQueueFamilies(Gfx.PhysicalDevice);
		uint32[?] queueFamilyIndices = .(indices.graphicsFamily.Value, indices.presentFamily.Value);

		if (indices.graphicsFamily != indices.presentFamily) {
			info.imageSharingMode = .VK_SHARING_MODE_CONCURRENT;
			info.queueFamilyIndexCount = 2;
			info.pQueueFamilyIndices = &queueFamilyIndices;
		}

		vkCreateSwapchainKHR(Gfx.Device, &info, null, &handle);
		if (handle == .Null) return Log.ErrorResult("Failed to create Vulkan swapchain");

		if (info.imageExtent.width != size.x || info.imageExtent.height != size.y) {
			Log.Warning("Selected swapchain size does not match requested size. Selected: [{}, {}] Requested: [{}, {}]", info.imageExtent.width, info.imageExtent.height, size.x, size.y);
		}

		GetImages(format, size);

		return .Ok;
	}

	private void GetImages(ImageFormat format, Vec2i size) {
		images.ClearAndDeleteItems();

		uint32 count = 0;
		vkGetSwapchainImagesKHR(Gfx.Device, handle, &count, null);

		VkImage[] rawImages = scope .[count];
		vkGetSwapchainImagesKHR(Gfx.Device, handle, &count, rawImages.Ptr);

		for (let i < count) {
			images.Add(new [Friend].(rawImages[i], default, true, format, .ColorAttachment, size, 1, scope $"Swapchain {i}"));

			if (Gfx.DebugUtilsExt) {
				VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
					objectType = .VK_OBJECT_TYPE_IMAGE,
					objectHandle = rawImages[i],
					pObjectName = scope $"[IMAGE] Swapchain {i}"
				};
				vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
			}
		}
	}

	public GpuImage GetImage(VkSemaphore semaphore) {
		vkAcquireNextImageKHR(Gfx.Device, handle, uint64.MaxValue, semaphore, .Null, &index);

		return images[index];
	}
}