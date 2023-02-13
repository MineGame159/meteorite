using System;
using System.Collections;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti.Graphics;

class GpuBufferManager {
	private List<GpuBuffer> buffers = new .() ~ delete _;

	public int Count => buffers.Count;

	[Tracy.Profile]
	public Result<GpuBuffer> Create(StringView name, GpuBufferType type, GpuBufferUsage usage, uint64 size) {
		// Return an empty buffer without memory if the size is 0
		if (size == 0) {
			return new [Friend]GpuBuffer(.Null, default, name, type, usage, size);
		}

		// Create buffer
		VkBufferCreateInfo bufferInfo = .() {
			usage = type.Vk,
			size = size
		};

		VmaAllocationCreateInfo allocationInfo = .() {
			usage = .VMA_MEMORY_USAGE_AUTO
		};

		if (usage & .Mappable != 0) allocationInfo.flags |= .VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT;
		if (usage & .TransferSrc != 0) bufferInfo.usage |= .VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		if (usage & .TransferDst != 0) bufferInfo.usage |= .VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		if (usage & .Dedicated != 0) allocationInfo.flags |= .VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;

		VkBuffer handle = ?;
		VmaAllocation allocation = ?;

		VkResult result = vmaCreateBuffer(Gfx.VmaAllocator, &bufferInfo, &allocationInfo, &handle, &allocation, null);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan buffer: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_BUFFER,
				objectHandle = handle,
				pObjectName = scope $"[BUFFER - {type.Char}] {name}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		// Return
		GpuBuffer buffer = new [Friend].(handle, allocation, name, type, usage, size);
		buffers.Add(buffer);

		return buffer;
	}

	public Result<void> EnsureSize(ref GpuBuffer buffer, uint64 size) {
		// Return if the buffer is big enough
		if (buffer.Size >= size) return .Ok;

		// Release the old buffer
		buffer.Release();

		// Create a new buffer
		switch (Create(buffer.Name, buffer.Type, buffer.Usage, size)) {
		case .Ok(let val):
			buffer = val;
			return .Ok;
		case .Err:
			return .Err;
		}
	}
}