using System;
using System.Threading;
using System.Diagnostics;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti.Graphics;

class GpuBuffer : DoubleRefCounted, IHashable {
	// Fields

	private VkBuffer handle;
	private VmaAllocation allocation;

	private append String name = .();
	private GpuBufferType type;
	private GpuBufferUsage usage;
	private uint64 size;

	private bool mapped;

	private bool valid = true;

	// Properties

	public VkBuffer Vk => handle;

	public StringView Name => name;
	public GpuBufferType Type => type;
	public GpuBufferUsage Usage => usage;
	public uint64 Size => size;

	// Constructors / Destructors

	private this(VkBuffer handle, VmaAllocation allocation, StringView name, GpuBufferType type, GpuBufferUsage usage, uint64 size) {
		this.handle = handle;
		this.allocation = allocation;
		this.name.Set(name);
		this.type = type;
		this.usage = usage;
		this.size = size;
	}

	public ~this() {
		if (size > 0) {
			vmaDestroyBuffer(Gfx.VmaAllocator, handle, allocation);
		}

		Gfx.Buffers.[Friend]buffers.Remove(this);
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

	// Buffer

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

	[Tracy.Profile]
	public Result<void> Upload(void* data, uint64 size) {
		void* buffer = Map().GetOrPropagate!();
		Internal.MemCpy(buffer, data, (.) size);
		Unmap().GetOrPropagate!();

		return .Ok;
	}

	public GpuBufferView View(uint64 offset, uint64 size) => .(this, offset, size);

	// Other

	public int GetHashCode() => (.) handle.Handle;

	public static operator GpuBufferView(GpuBuffer buffer) => .(buffer, 0, buffer.size);
}

struct GpuBufferView : this(GpuBuffer buffer, uint64 offset, uint64 size), IHashable {
	public Result<void*> Map() => &((uint8*) buffer.Map().GetOrPropagate!())[offset];
	public Result<void> Unmap() => buffer.Unmap();

	public Result<void> Upload(void* data, uint64 size) {
		void* buffer = Map().GetOrPropagate!();
		Internal.MemCpy(buffer, data, (.) size);
		Unmap().GetOrPropagate!();

		return .Ok;
	}

	public bool Valid => buffer != null && offset >= 0 && size > 0;

	public int GetHashCode() {
		int hash = buffer.GetHashCode();

		hash = Utils.CombineHashCode(hash, (.) offset);
		hash = Utils.CombineHashCode(hash, (.) size);

		return hash;
	}
}