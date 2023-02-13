using System;
using System.Threading;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti.Graphics;

class GpuImage : DoubleRefCounted, IHashable {
	// Fields

	private VkImage handle;
	private VmaAllocation allocation;
	private bool swapchain;

	private append String name = .();
	private ImageFormat format;
	private ImageUsage usage;
	private Vec2i size;

	private GpuImageView view;
	private ImageAccess[] mipAccesses ~ delete _;

	private bool valid = true;

	// Properties

	public VkImage Vk => handle;

	public StringView Name => name;
	public ImageFormat Format => format;
	public ImageUsage Usage => usage;

	public Vec2i Size => size;
	public int MipLevels => mipAccesses.Count;

	// Constructors / Destructors

	private this(VkImage handle, VmaAllocation allocation, bool swapchain, StringView name, ImageFormat format, ImageUsage usage, Vec2i size, int mipLevels) {
		this.handle = handle;
		this.allocation = allocation;
		this.swapchain = swapchain;
		this.name.Set(name);
		this.format = format;
		this.usage = usage;
		this.size = size;

		this.mipAccesses = new .[mipLevels];
		this.mipAccesses.SetAll(.Undefined);
	}

	public ~this() {
		// Destroy image views
		if (view.Valid) {
			vkDestroyImageView(Gfx.Device, view.Vk, null);
		}

		// Destroy image
		if (!swapchain) {
			vmaDestroyImage(Gfx.VmaAllocator, handle, allocation);

			Gfx.Images.[Friend]images.Remove(this);
		}
	}

	// Reference counting

	protected override void Delete() {
		if (valid) {
			AddWeakRef();
			Gfx.ReleaseNextFrame(this);

			valid = false;
		}
		else {
			delete this;
		}
	}

	// Image

	public int GetWidth(int mipLevel = 0) => Math.Max(1, size.x >> mipLevel);
	public int GetHeight(int mipLevel = 0) => Math.Max(1, size.y >> mipLevel);
	public uint64 GetByteSize(int mipLevel = 0) => (.) (GetWidth(mipLevel) * GetHeight(mipLevel)) * format.Bytes;

	public ImageAccess GetAccess(int mipLevel = 0) => mipAccesses[mipLevel];

	public Result<GpuImageView> GetView() {
		// Create view if it doesn't exist
		if (!view.Valid) {
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

			VkImageView handle = .Null;
			vkCreateImageView(Gfx.Device, &info, null, &handle);
			if (handle == .Null) {
				Log.ErrorResult("Failed to create view for a GpuImage: {}", name);
				return .Err;
			}

			if (Gfx.DebugUtilsExt) {
				VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
					objectType = .VK_OBJECT_TYPE_IMAGE_VIEW,
					objectHandle = handle,
					pObjectName = scope $"[IMAGE_VIEW] {name}"
				};
				vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
			}

			view = .(this, handle);
		}
		
		// Return
		return view;
	}

	// Other

	public int GetHashCode() => (.) handle.Handle;
}

struct GpuImageView : IEquatable<Self>, IHashable {
	private GpuImage image;
	private VkImageView handle;

	public GpuImage Image => image;
	public VkImageView Vk => handle;

	public bool Valid => image != null && handle != .Null;

	public this(GpuImage image, VkImageView handle) {
		this.image = image;
		this.handle = handle;
	}

	public bool Equals(Self other) => handle == other.handle;

	public int GetHashCode() => (.) handle.Handle;

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}