using System;
using System.Collections;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti;

class BumpGpuBufferAllocator {
	private BufferType[Enum.GetCount<GpuBufferType>()] bufferTypes;
	private GpuBufferAllocatorStats stats;

	public ~this() {
		for (let bufferType in bufferTypes) delete bufferType;
	}

	public GpuBufferAllocatorStats Stats => stats;

	public GpuBufferView Allocate(GpuBufferType type, uint64 size) {
		// Get buffer type
		BufferType bufferType = bufferTypes[type.Underlying];

		if (bufferType == null) {
			bufferType = new .(this, type);
			bufferTypes[type.Underlying] = bufferType;
		}

		// Update stats
		stats.AllocationCount++;
		stats.UsedMemory += size;

		// Allocate
		return bufferType.Allocate(size);
	}

	public void Free(GpuBufferView buffer) {}

	public void FreeAll() {
		for (let bufferType in bufferTypes) bufferType?.FreeAll();
		stats = .();
	}

	class BufferType {
		private BumpGpuBufferAllocator allocator;
		private GpuBufferType type;
		private List<Block> blocks = new .() ~ DeleteContainerAndDisposeItems!(_);

		public this(BumpGpuBufferAllocator allocator, GpuBufferType type) {
			this.allocator = allocator;
			this.type = type;

			CreateBlock(0);
		}

		public GpuBufferAllocatorStats Stats { get {
			GpuBufferAllocatorStats stats = .();

			for (let block in blocks) {
				VmaStatistics vmaStats = ?;
				vmaGetVirtualBlockStatistics(block.block, &vmaStats);

				stats.AllocationCount += vmaStats.blockCount;
				stats.UsedMemory += vmaStats.allocationBytes;
				stats.AllocatedMemory += vmaStats.blockBytes;
			}

			return stats;
		} }

		public GpuBufferView Allocate(uint64 size) {
			// Try to allocate from existing blocks
			for (let block in blocks) {
				if (Allocate(block, size) case .Ok(let val)) return val;
			}

			// Create new block
			Block block = CreateBlock(size);
			return Allocate(block, size);
		}

		public void FreeAll() {
			// Free first block if there is only one
			if (blocks.Count <= 1) {
				for (let block in blocks) vmaClearVirtualBlock(block.block);

				return;
			}

			// Combine all blocks into one
			//     Get total size and destroy blocks
			uint64 totalSize = 0;

			for (let block in blocks) {
				totalSize += block.buffer.size;
				block.Dispose();
			}

			blocks.Clear();

			//     Create block big enough to hold previous total size
			CreateBlock(totalSize);
		}

		private Block CreateBlock(uint64 minSize) {
			// Create buffer
			GpuBuffer buffer = Gfx.Buffers.Create(type, .Mappable | .TransferSrc, Math.Max(minSize, 1024 * 1024), scope $"Bump {blocks.Count}");

			// Create virtual block
			VmaVirtualBlockCreateInfo info = .() {
				size = (.) buffer.size,
				flags = .VMA_VIRTUAL_BLOCK_CREATE_LINEAR_ALGORITHM_BIT
			};

			VmaVirtualBlock virtualBlock = ?;
			vmaCreateVirtualBlock(&info, &virtualBlock);
			
			// Create and return block
			Block block = .(buffer, virtualBlock);
			blocks.Add(block);

			allocator.stats.AllocatedMemory += buffer.size;
			return block;
		}

		private Result<GpuBufferView> Allocate(Block block, uint64 size) {
			VmaVirtualAllocationCreateInfo info = .() {
				size = (.) size
			};

			if (type == .Uniform) info.alignment = (.) Gfx.Properties.limits.minUniformBufferOffsetAlignment;
			else if (type == .Storage) info.alignment = (.) Gfx.Properties.limits.minStorageBufferOffsetAlignment;

			VmaVirtualAllocation allocation = ?;
			VkDeviceSize offset = 0;
			if (vmaVirtualAllocate(block.block, &info, &allocation, &offset) != .VK_SUCCESS) return .Err;

			return block.buffer.View(offset, size);
		}

		struct Block : this(GpuBuffer buffer, VmaVirtualBlock block), IDisposable {
			public void Dispose() {
				vmaDestroyVirtualBlock(block);
				delete buffer;
			}
		}
	}
}