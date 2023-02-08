using System;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti;

public struct ColorAttachment : this(GpuImage image, Color? clearColor = null) {}
public struct DepthAttachment : this(GpuImage image, float? clearDepth = null) {}

class RenderPass : IDisposable {
	private String name ~ delete _;

	public this(StringView name) {
		this.name = new .(name);
	}

	public StringView Name => name;

	public void Dispose() {
		Gfx.RenderPasses.[Friend]End();
	}
}

class RenderPassManager {
	private Dictionary<StringView, RenderPass> passes = new .() ~ DeleteDictionaryAndValues!(_);

	private CommandBuffer cmds;
	private RenderPass current;

	public RenderPass Current => current;

	public RenderPass Begin(CommandBuffer cmds, StringView name, DepthAttachment? depthAttachment, params ColorAttachment[] colorAttachments) {
		Runtime.Assert(current == null);

		// Check cache
		RenderPass pass;

		if (passes.TryGetValue(name, out pass)) {
			BeginImpl(cmds, pass, depthAttachment, colorAttachments);
			return pass;
		}

		// Create new pass
		pass = new .(name);
		passes[pass.Name] = pass;

		BeginImpl(cmds, pass, depthAttachment, colorAttachments);
		return pass;
	}

	private void End() {
		Runtime.Assert(current != null);

		vkCmdEndRendering(cmds.[Friend]handle);
		cmds.PopDebugGroup();

		current = null;
	}

	private void BeginImpl(CommandBuffer cmds, RenderPass pass, DepthAttachment? depthAttachment, ColorAttachment[] colorAttachments) {
		Debug.Assert(colorAttachments.Count <= PipelineInfo.MAX_TARGETS);

		VkRenderingAttachmentInfo[] rawColorAttachments = scope .[colorAttachments.Count];
		VkRenderingAttachmentInfo rawDepthAttachment;

		for (int i < colorAttachments.Count) {
			ColorAttachment attachment = colorAttachments[i];
			Color clearColor = attachment.clearColor.GetValueOrDefault();

			cmds.TransitionImage(attachment.image, .ColorAttachment);

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

			cmds.TransitionImage(attachment.image, .DepthAttachment);

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
			renderArea = .((.) cmds.[Friend]viewport.x, (.) cmds.[Friend]viewport.y),
			layerCount = 1,
			colorAttachmentCount = (.) rawColorAttachments.Count,
			pColorAttachments = rawColorAttachments.Ptr,
			pDepthAttachment = depthAttachment.HasValue ? &rawDepthAttachment : null
		};

		cmds.PushDebugGroup(pass.Name);
		vkCmdBeginRendering(cmds.[Friend]handle, &info);

		this.cmds = cmds;
		this.current = pass;
	}
}