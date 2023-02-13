using System;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

enum IndexType {
	case Uint16,
		 Uint32;

	public VkIndexType Vk { get {
		return this == .Uint16 ? .VK_INDEX_TYPE_UINT16 : .VK_INDEX_TYPE_UINT32;
	} }
}

class CommandBuffer {
	// Fields

	private VkCommandBuffer handle;
	private bool building;

	private RenderPass currentPass;

	// Properties

	public VkCommandBuffer Vk => handle;

	// Constructors / Destructors

	private this(VkCommandBuffer handle) {
		this.handle = handle;
	}

	// Command Buffer

	public void Begin() {
		Runtime.Assert(!building);

		VkCommandBufferBeginInfo info = .() {
			flags = .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
		};

		vkBeginCommandBuffer(handle, &info);
		vkCmdWriteTimestamp(handle, .VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, Gfx.Queries.pool, Gfx.Queries.Get());

		building = true;
	}

	public void End() {
		Runtime.Assert(building);

		vkCmdWriteTimestamp(handle, .VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, Gfx.Queries.pool, Gfx.Queries.Get());
		vkEndCommandBuffer(handle);

		building = false;
	}

	public void TransitionImage(GpuImage image, ImageAccess next, int mipLevel = 0) {
		if (image.GetAccess(mipLevel) == next) return;

		var next;

		ThsvsGlobalBarrier* globalBarrier = null;
		ThsvsBufferBarrier* bufferBarrier = null;

		ThsvsAccessType prev_ = image.GetAccess(mipLevel).Thsvs;
		ThsvsAccessType next_ = next.Thsvs;

		ThsvsImageBarrier imageBarrier = .() {
			prevAccessCount = 1,
			pPrevAccesses = &prev_,
			nextAccessCount = 1,
			pNextAccesses = &next_,
			prevLayout = .THSVS_IMAGE_LAYOUT_OPTIMAL,
			nextLayout = .THSVS_IMAGE_LAYOUT_OPTIMAL,
			srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			image = image.[Friend]handle,
			subresourceRange = .() {
				aspectMask = image.Usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
				baseMipLevel = (.) mipLevel,
				levelCount = 1,
				layerCount = 1
			}
		};

		thsvsCmdPipelineBarrier(handle, globalBarrier, 0, bufferBarrier, 1, &imageBarrier);
		image.[Friend]mipAccesses[mipLevel] = next;
	}

	public void CopyBufferToBuffer(GpuBufferView src, GpuBufferView dst, uint64 size) {
		VkBufferCopy info = .() {
			srcOffset = src.offset,
			dstOffset = dst.offset,
			size = size
		};

		vkCmdCopyBuffer(handle, src.buffer.[Friend]handle, dst.buffer.[Friend]handle, 1, &info);
	}

	public void CopyBufferToImage(GpuBufferView src, GpuImage dst, int mipLevel = 0) {
		VkBufferImageCopy info = .() {
			bufferOffset = src.offset,
			imageSubresource = .() {
				aspectMask = dst.Usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
				mipLevel = (.) mipLevel,
				layerCount = 1
			},
			imageExtent = .() {
				width = (.) dst.GetWidth(mipLevel),
				height = (.) dst.GetHeight(mipLevel),
				depth = 1
			}
		};

		TransitionImage(dst, .Write, mipLevel);
		vkCmdCopyBufferToImage(handle, src.buffer.[Friend]handle, dst.[Friend]handle, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &info);
		TransitionImage(dst, .Sample, mipLevel);
	}

	public void CopyImageToBuffer(GpuImage src, GpuBufferView dst, int mipLevel = 0) {
		VkBufferImageCopy info = .() {
			bufferOffset = dst.offset,
			imageSubresource = .() {
				aspectMask = src.Usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
				mipLevel = (.) mipLevel,
				layerCount = 1
			},
			imageExtent = .() {
				width = (.) src.GetWidth(mipLevel),
				height = (.) src.GetHeight(mipLevel),
				depth = 1
			}
		};

		TransitionImage(src, .Read, mipLevel);
		vkCmdCopyImageToBuffer(handle, src.[Friend]handle, .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, dst.buffer.[Friend]handle, 1, &info);
		TransitionImage(src, .ColorAttachment, mipLevel);
	}

	public void BlitImage(GpuImage src, GpuImage dst, int mipLevel = 0) {
		VkImageBlit info = .() {
			srcSubresource = .() {
				aspectMask = src.Usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
				mipLevel = (.) mipLevel,
				layerCount = 1
			},
			srcOffsets = .(
				.(),
				.() {
					z = 1
				}
			),
			dstSubresource = .() {
				aspectMask = src.Usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
				mipLevel = (.) mipLevel,
				layerCount = 1
			},
			dstOffsets = .(
				.(),
				.() {
					z = 1
				}
			)
		};

		TransitionImage(src, .Read, mipLevel);
		TransitionImage(dst, .Write, mipLevel);

		vkCmdBlitImage(handle, src.[Friend]handle, .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, dst.[Friend]handle, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &info, .VK_FILTER_NEAREST);

		TransitionImage(src, .ColorAttachment, mipLevel);
	}

	public void PushDebugGroup(StringView name, Color color = .BLACK) {
		if (!Gfx.DebugUtilsExt) return;

		VkDebugUtilsLabelEXT info = .() {
			pLabelName = name.ToScopeCStr!(),
			color = .(color.R, color.G, color.B, color.A)
		};

		vkCmdBeginDebugUtilsLabelEXT(handle, &info);
	}

	public void PopDebugGroup() {
		if (!Gfx.DebugUtilsExt) return;

		vkCmdEndDebugUtilsLabelEXT(handle);
	}
}