using System;
using System.Collections;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti;

enum GpuBufferType {
	case None,
		 Vertex,
		 Index,
		 Uniform,
		 Storage;

	public VkBufferUsageFlags Vk { get {
		switch (this) {
		case .None:		return .None;
		case .Vertex:	return .VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
		case .Index:	return .VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
		case .Uniform:	return .VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
		case .Storage:	return .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
		}
	} }

	public char8 Char { get {
		switch (this) {
		case .None:		return 'N';
		case .Vertex:	return 'V';
		case .Index:	return 'I';
		case .Uniform:	return 'U';
		case .Storage:	return 'S';
		}
	} }
}

enum GpuBufferUsage {
	case None = 0,
		 Mappable = 1,
		 TransferSrc = 2,
		 TransferDst = 4,
		 Dedicated = 8;
}

class GpuBuffer {
	private VkBuffer handle;
	private VmaAllocation allocation;

	public String name ~ delete _;
	public GpuBufferType type;
	public GpuBufferUsage usage;
	public uint64 size;

	private bool mapped;
	private List<bool*> invalidatePointers = new .() ~ delete _;

	private this(VkBuffer handle, VmaAllocation allocation, StringView name, GpuBufferType type, GpuBufferUsage usage, uint64 size) {
		this.handle = handle;
		this.allocation = allocation;
		this.name = new .(name);
		this.type = type;
		this.usage = usage;
		this.size = size;
	}

	public ~this() {
		Destroy();
	}

	private void Destroy() {
		if (size > 0) vmaDestroyBuffer(Gfx.VmaAllocator, handle, allocation);
	}

	public Result<void*> Map() {
		if (mapped) return .Err;

		void* data = ?;
		if (vmaMapMemory(Gfx.VmaAllocator, allocation, &data) != .VK_SUCCESS) return .Err;

		mapped = true;
		return data;
	}

	public Result<void> Unmap() {
		if (!mapped) return .Err;

		vmaUnmapMemory(Gfx.VmaAllocator, allocation);
		mapped = false;

		return .Ok;
	}

	public Result<void> Upload(void* data, uint64 size) {
		void* buffer = Map().GetOrPropagate!();
		Internal.MemCpy(buffer, data, (.) size);
		Unmap().GetOrPropagate!();

		return .Ok;
	}

	public Result<void> EnsureCapacity(uint64 capacity) {
		if (mapped) return .Err;
		if (size >= capacity) return .Ok;

		Destroy();

		let (handle, allocation) = Gfx.Buffers.[Friend]CreateRaw(type, usage, capacity, name).Value;
		this.handle = handle;
		this.allocation = allocation;

		size = capacity;

		for (let pointer in invalidatePointers) *pointer = true;

		return .Ok;
	}

	public GpuBufferView View(uint64 offset, uint64 size) => .(this, offset, size);

	public static operator GpuBufferView(GpuBuffer buffer) => .(buffer, 0, buffer.size);
}

struct GpuBufferView : this(GpuBuffer buffer, uint64 offset, uint64 size) {
	public Result<void*> Map() => &((uint8*) buffer.Map().GetOrPropagate!())[offset];
	public Result<void> Unmap() => buffer.Unmap();

	public Result<void> Upload(void* data, uint64 size) {
		void* buffer = Map().GetOrPropagate!();
		Internal.MemCpy(buffer, data, (.) size);
		Unmap().GetOrPropagate!();

		return .Ok;
	}

	public bool Valid => buffer != null && offset >= 0 && size > 0;
}

class GpuBufferManager {
	private Result<(VkBuffer, VmaAllocation)> CreateRaw(GpuBufferType type, GpuBufferUsage usage, uint64 size, StringView name) {
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

		return (handle, allocation);
	}

	public GpuBuffer Create(GpuBufferType type, GpuBufferUsage usage, uint64 size, StringView name) {
		if (size == 0) return new [Friend].(.Null, default, name, type, usage, size);

		switch (CreateRaw(type, usage, size, name)) {
		case .Err:			return null;
		case .Ok(let val):	return new [Friend].(val.0, val.1, name, type, usage, size);
		}
	}
}