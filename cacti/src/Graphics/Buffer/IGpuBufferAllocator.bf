using System;

namespace Cacti.Graphics;

struct GpuBufferAllocatorStats {
	public int AllocationCount;

	public uint64 UsedMemory;
	public uint64 AllocatedMemory;
}

interface IGpuBufferAllocator {
	GpuBufferAllocatorStats Stats { get; }

	GpuBufferView Allocate(GpuBufferType type, uint64 size);

	void Free(GpuBufferView buffer);

	void FreeAll();
}