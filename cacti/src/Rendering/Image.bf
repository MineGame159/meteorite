using System;
using System.Collections;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti;

enum ImageFormat {
	case RGBA,
		 BGRA,
		 RGBA16,
		 RGBA32,
		 R8,
		 Depth;

	public VkFormat Vk { get {
		switch (this) {
		case .RGBA:		return .VK_FORMAT_R8G8B8A8_UNORM;
		case .BGRA:		return .VK_FORMAT_B8G8R8A8_UNORM;
		case .RGBA16:	return .VK_FORMAT_R16G16B16A16_SFLOAT;
		case .RGBA32:	return .VK_FORMAT_R32G32B32A32_SFLOAT;
		case .R8:		return .VK_FORMAT_R8_UNORM;
		case .Depth:	return .VK_FORMAT_D32_SFLOAT;
		}
	} }

	public uint64 Bytes { get {
		return this == .RGBA16 ? 8 : 4;
	} }
}

enum ImageUsage {
	case Normal,
		 ColorAttachment,
		 DepthAttachment;

	public VkImageUsageFlags Vk { get {
		switch (this) {
		case .Normal:			return .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		case .ColorAttachment:	return .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		case .DepthAttachment:	return .VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		}
	} }
}

enum ImageAccess {
	case Undefined,
		 ColorAttachment,
		 DepthAttachment,
		 Write,
		 Sample,
		 Present;

	public ThsvsAccessType Thsvs { get {
		switch (this) {
		case .Undefined:		return .THSVS_ACCESS_NONE;
		case .ColorAttachment:	return .THSVS_ACCESS_COLOR_ATTACHMENT_WRITE;
		case .DepthAttachment:	return .THSVS_ACCESS_DEPTH_ATTACHMENT_WRITE_STENCIL_READ_ONLY;
		case .Write:			return .THSVS_ACCESS_TRANSFER_WRITE;
		case .Sample:			return .THSVS_ACCESS_FRAGMENT_SHADER_READ_SAMPLED_IMAGE_OR_UNIFORM_TEXEL_BUFFER;
		case .Present:			return .THSVS_ACCESS_PRESENT;
		}
	} }
}

typealias GpuImageView = VkImageView;

class GpuImage {
	private VkImage handle;
	private VmaAllocation allocation;
	private bool external;

	public ImageFormat format;
	public ImageUsage usage;
	public Vec2i size;
	public String name ~ delete _;

	private GpuImageView view;
	private ImageAccess[] mipAccesses ~ delete _;

	private List<bool*> invalidatePointers = new .() ~ delete _;

	private this(VkImage handle, VmaAllocation allocation, bool external, ImageFormat format, ImageUsage usage, Vec2i size, int mipLevels, StringView name) {
		this.handle = handle;
		this.allocation = allocation;
		this.external = external;
		this.format = format;
		this.usage = usage;
		this.size = size;
		this.name = new .(name);

		this.mipAccesses = new .[mipLevels];
		this.mipAccesses.SetAll(.Undefined);
	}

	public ~this() {
		Destroy();
	}

	private void Destroy() {
		if (view != .Null) {
			vkDestroyImageView(Gfx.Device, view, null);
			view = .Null;
		}

		if (!external) vmaDestroyImage(Gfx.VmaAllocator, handle, allocation);
	}

	public int Width => size.x;
	public int Height => size.y;
	public uint64 Bytes => (.) (size.x * size.y) * format.Bytes;

	public int GetWidth(int mipLevel = 0) => Math.Max(1, size.x >> mipLevel);
	public int GetHeight(int mipLevel = 0) => Math.Max(1, size.y >> mipLevel);
	public uint64 GetBytes(int mipLevel = 0) => (.) (GetWidth(mipLevel) * GetHeight(mipLevel)) * format.Bytes;

	public int MipLevels => mipAccesses.Count;

	public ImageAccess Access => mipAccesses[0];
	public ImageAccess GetAccess(int mipLevel = 0) => mipAccesses[mipLevel];

	public GpuImageView View { get {
		if (view == .Null) {
			VkImageViewCreateInfo info = .() {
				image = handle,
				viewType = .VK_IMAGE_VIEW_TYPE_2D,
				format = format.Vk,
				components = .() {
					r = .VK_COMPONENT_SWIZZLE_IDENTITY,
					g = .VK_COMPONENT_SWIZZLE_IDENTITY,
					b = .VK_COMPONENT_SWIZZLE_IDENTITY,
					a = .VK_COMPONENT_SWIZZLE_IDENTITY
				},
				subresourceRange = .() {
					aspectMask = usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
					baseMipLevel = 0,
					levelCount = (.) MipLevels,
					baseArrayLayer = 0,
					layerCount = 1
				}
			};

			vkCreateImageView(Gfx.Device, &info, null, &view);
			if (view == .Null) Log.ErrorResult("Failed to create view for a GpuImage");

			if (Gfx.DebugUtilsExt) {
				VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
					objectType = .VK_OBJECT_TYPE_IMAGE_VIEW,
					objectHandle = view,
					pObjectName = scope $"[IMAGE_VIEW] {name}"
				};
				vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
			}
		}

		return view;
	} }

	public void Resize(Vec2i size) {
		if (this.size == size) return;

		Destroy();

		let (handle, allocation) = Gfx.Images.[Friend]CreateRaw(format, usage, size, name, MipLevels).Value;
		this.handle = handle;
		this.allocation = allocation;

		this.size = size;
		this.mipAccesses.SetAll(.Undefined);

		for (let pointer in invalidatePointers) *pointer = true;
	}
}

class ImageManager {
	private Result<(VkImage, VmaAllocation)> CreateRaw(ImageFormat format, ImageUsage usage, Vec2i size, StringView name, int mipLevels = 1) {
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

		VkImage image = ?;
		VmaAllocation allocation = ?;
		VkResult result = vmaCreateImage(Gfx.VmaAllocator, &info, &allocationInfo, &image, &allocation, null);

		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan image: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_IMAGE,
				objectHandle = image,
				pObjectName = scope $"[IMAGE] {name}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		return (image, allocation);
	}

	public Result<GpuImage> Create(ImageFormat format, ImageUsage usage, Vec2i size, StringView name, int mipLevels = 1) {
		switch (CreateRaw(format, usage, size, name, mipLevels)) {
		case .Err:			return .Err;
		case .Ok(let val):	return new [Friend]GpuImage(val.0, val.1, false, format, usage, size, mipLevels, name);
		}
	}
}