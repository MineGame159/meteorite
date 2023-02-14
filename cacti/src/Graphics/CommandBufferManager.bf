using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class CommandBufferManager {
	private VkCommandPool pool ~ vkDestroyCommandPool(Gfx.Device, _, null);

	private List<CommandBuffer> freeBuffers = new .() ~ DeleteContainerAndItems!(_);
	private List<CommandBuffer> usedBuffers = new .() ~ DeleteContainerAndItems!(_);

	public TimeSpan TotalDuration { get; private set; }

	public this() {
		VkCommandPoolCreateInfo info = .() {
			queueFamilyIndex = Gfx.FindQueueFamilies(Gfx.PhysicalDevice).graphicsFamily.Value
		};

		vkCreateCommandPool(Gfx.Device, &info, null, &pool);
		if (pool == .Null) Log.ErrorResult("Failed to create Vulkan command pool");
	}

	[Tracy.Profile]
	public void NewFrame() {
		// Calculate total duration
		TotalDuration = .Zero;

		for (CommandBuffer cmds in usedBuffers) {
			TotalDuration += cmds.Duration;
		}

		// Free command buffers
		freeBuffers.AddRange(usedBuffers);
		usedBuffers.Clear();

		// Reset pool
		vkResetCommandPool(Gfx.Device, pool, .None);
	}

	[Tracy.Profile]
	public Result<CommandBuffer> GetBuffer() {
		// Try to get a free buffer
		if (freeBuffers.Count > 0) {
			CommandBuffer buffer = freeBuffers.PopBack();
			usedBuffers.Add(buffer);

			return buffer;
		}

		// Create buffer
		VkCommandBufferAllocateInfo info = .() {
			commandPool = pool,
			commandBufferCount = 1,
			level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY
		};

		VkCommandBuffer handle = ?;
		vkAllocateCommandBuffers(Gfx.Device, &info, &handle);
		if (handle == .Null) {
			Log.ErrorResult("Failed to allocate Vulkan command buffer");
			return .Err;
		}

		CommandBuffer buffer = new [Friend].(handle);
		usedBuffers.Add(buffer);

		return buffer;
	}
}