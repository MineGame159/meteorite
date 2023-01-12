using System;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;

namespace Cacti;

enum IndexType {
	case Uint16,
		 Uint32;

	public VkIndexType Vk { get {
		return this == .Uint16 ? .VK_INDEX_TYPE_UINT16 : .VK_INDEX_TYPE_UINT32;
	} }
}

class CommandBuffer {
	private VkCommandBuffer handle;
	
	private Vec2i viewport;
	private Pipeline boundPipeline;

	private GpuBufferView boundVbo, boundIbo;
	
	private this(VkCommandBuffer handle) {
		this.handle = handle;
	}

	private void ResetState() {
		boundPipeline = null;

		boundVbo = default;
		boundIbo = default;
	}

	public void Begin() {
		VkCommandBufferBeginInfo info = .() {
			flags = .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
		};

		vkBeginCommandBuffer(handle, &info);
	}

	public void End() {
		vkEndCommandBuffer(handle);
	}

	public void BeginPass(DepthAttachment? depthAttachment, params ColorAttachment[] colorAttachments) {
		Debug.Assert(colorAttachments.Count <= PipelineInfo.MAX_TARGETS);

		VkRenderingAttachmentInfo[] rawColorAttachments = scope .[colorAttachments.Count];
		VkRenderingAttachmentInfo rawDepthAttachment;
		
		for (int i < colorAttachments.Count) {
			ColorAttachment attachment = colorAttachments[i];
			Color clearColor = attachment.clearColor.GetValueOrDefault();

			TransitionImage(attachment.image, .ColorAttachment);

			rawColorAttachments[i] = .() {
				imageView = attachment.image.View,
				imageLayout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
				loadOp = attachment.clearColor.HasValue ? .VK_ATTACHMENT_LOAD_OP_CLEAR : .VK_ATTACHMENT_LOAD_OP_LOAD,
				storeOp = .VK_ATTACHMENT_STORE_OP_STORE,
				clearValue = .() {
					color = .(clearColor.R, clearColor.G, clearColor.B, clearColor.A)
				}
			};
		}

		if (depthAttachment.HasValue) {
			DepthAttachment attachment = depthAttachment.Value;

			TransitionImage(attachment.image, .DepthAttachment);

			rawDepthAttachment = .() {
				imageView = attachment.image.View,
				imageLayout = .VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL,
				loadOp = attachment.clearDepth.HasValue ? .VK_ATTACHMENT_LOAD_OP_CLEAR : .VK_ATTACHMENT_LOAD_OP_LOAD,
				storeOp = .VK_ATTACHMENT_STORE_OP_STORE,
				clearValue = .() {
					depthStencil = .() {
						depth = attachment.clearDepth.GetValueOrDefault()
					}
				}
			};
		}

		VkRenderingInfo info = .() {
			renderArea = .((.) viewport.x, (.) viewport.y),
			layerCount = 1,
			colorAttachmentCount = (.) rawColorAttachments.Count,
			pColorAttachments = rawColorAttachments.Ptr,
			pDepthAttachment = depthAttachment.HasValue ? &rawDepthAttachment : null
		};

		vkCmdBeginRendering(handle, &info);
	}

	public void EndPass() {
		vkCmdEndRendering(handle);
	}

	public struct ColorAttachment : this(GpuImage image, Color? clearColor) {}
	public struct DepthAttachment : this(GpuImage image, float? clearDepth) {}

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
				aspectMask = image.usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
				baseMipLevel = (.) mipLevel,
				levelCount = 1,
				layerCount = 1
			}
		};

		thsvsCmdPipelineBarrier(handle, globalBarrier, 0, bufferBarrier, 1, &imageBarrier);
		image.[Friend]mipAccesses[mipLevel] = next;
	}

	public void SetViewport(Vec2i size, bool flipY = true, bool scissor = false) {
		VkViewport info = .() {
			x = 0,
			y = flipY ? size.y : 0,
			width = size.x,
			height = flipY ? -size.y : size.y,
			minDepth = 0,
			maxDepth = 1
		};

		vkCmdSetViewport(handle, 0, 1, &info);
		viewport = size;
		
		if (scissor) SetScissor(.(), size);
	}

	public void SetScissor(Vec2i pos, Vec2i size) {
		VkRect2D info = .() {
			offset = .((.) pos.x, (.) pos.y),
			extent = .((.) size.x, (.) size.y)
		};

		vkCmdSetScissor(handle, 0, 1, &info);
	}

	public void Bind(Pipeline pipeline) {
		if (boundPipeline == pipeline) return;

		vkCmdBindPipeline(handle, .VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline.Vk);
		boundPipeline = pipeline;
	}

	public void Bind(DescriptorSet set, uint32 index) {
		set.Validate();
		vkCmdBindDescriptorSets(handle, .VK_PIPELINE_BIND_POINT_GRAPHICS, boundPipeline.Layout, index, 1, &set.[Friend]handle, 0, null);
	}

	public void Bind(GpuBufferView view, IndexType indexType = .Uint32) {
		var view;

		switch (view.buffer.type) {
		case .Vertex:
			if (boundVbo != view) {
				vkCmdBindVertexBuffers(handle, 0, 1, &view.buffer.[Friend]handle, &view.offset);
				boundVbo = view;
			}
		case .Index:
			if (boundIbo != view) {
				vkCmdBindIndexBuffer(handle, view.buffer.[Friend]handle, view.offset, indexType.Vk);
				boundIbo = view;
			}
		default:
			Log.Error("{} buffer cannot be bound to a command buffer", view.buffer.type);
		}
	}

	public void SetPushConstants(void* value, uint32 size) {
		vkCmdPushConstants(handle, boundPipeline.Layout, .VK_SHADER_STAGE_VERTEX_BIT | .VK_SHADER_STAGE_FRAGMENT_BIT, 0, size, value);
	}

	public void SetPushConstants<T>(T value) {
		var value;
		SetPushConstants(&value, (.) sizeof(T));
	}

	public void DrawIndexed(uint32 indexCount, uint32 firstIndex = 0, int32 vertexOffset = 0) {
		vkCmdDrawIndexed(handle, indexCount, 1, firstIndex, vertexOffset, 0);
	}

	public void Draw(BuiltMesh mesh) {
		if (mesh.indexCount == 0) return;

		Bind(mesh.vbo);
		Bind(mesh.ibo);
		DrawIndexed(mesh.indexCount);
	}

	public void CopyBufferToBuffer(GpuBufferView src, GpuBufferView dst, uint64 size) {
		VkBufferCopy info = .() {
			srcOffset = src.offset,
			dstOffset = dst.offset,
			size = size
		};

		VulkanNative.vkCmdCopyBuffer(handle, src.buffer.[Friend]handle, dst.buffer.[Friend]handle, 1, &info);
	}

	public void CopyBufferToImage(GpuBufferView src, GpuImage dst, int mipLevel = 0) {
		VkBufferImageCopy info = .() {
			bufferOffset = src.offset,
			imageSubresource = .() {
				aspectMask = dst.usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
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
				aspectMask = src.usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
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
				aspectMask = src.usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
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
				aspectMask = src.usage == .DepthAttachment ? .VK_IMAGE_ASPECT_DEPTH_BIT : .VK_IMAGE_ASPECT_COLOR_BIT,
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

class CommandBufferManager {
	private VkCommandPool handle ~ vkDestroyCommandPool(Gfx.Device, _, null);

	private List<CommandBuffer> freeBuffers = new .() ~ DeleteContainerAndItems!(_);
	private List<CommandBuffer> usedBuffers = new .() ~ DeleteContainerAndItems!(_);

	public this() {
		VkCommandPoolCreateInfo info = .() {
			queueFamilyIndex = Gfx.FindQueueFamilies(Gfx.PhysicalDevice).graphicsFamily.Value
		};

		vkCreateCommandPool(Gfx.Device, &info, null, &handle);
		if (handle == .Null) Log.ErrorResult("Failed to create Vulkan command pool");
	}

	public void NewFrame() {
		for (let buffer in usedBuffers) buffer.[Friend]ResetState();

		freeBuffers.AddRange(usedBuffers);
		usedBuffers.Clear();

		vkResetCommandPool(Gfx.Device, handle, .None);
	}

	public CommandBuffer GetBuffer() {
		// Try to get a free buffer
		if (freeBuffers.Count > 0) {
			CommandBuffer buffer = freeBuffers.PopBack();
			usedBuffers.Add(buffer);

			return buffer;
		}

		// Create buffer
		VkCommandBufferAllocateInfo info = .() {
			commandPool = handle,
			commandBufferCount = 1,
			level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY
		};

		VkCommandBuffer handle = ?;
		vkAllocateCommandBuffers(Gfx.Device, &info, &handle);
		if (handle == .Null) {
			Log.ErrorResult("Failed to allocate Vulkan command buffer");
			return null;
		}

		CommandBuffer buffer = new [Friend].(handle);
		usedBuffers.Add(buffer);

		return buffer;
	}
}