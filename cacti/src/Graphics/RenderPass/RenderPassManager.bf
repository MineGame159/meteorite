using System;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

struct DepthAttachment : this(GpuImage image, float? clearValue = null), IEquatable<Self>, IHashable {
	public bool Equals(Self other) => image == other.image && clearValue == other.clearValue;

	public int GetHashCode() => Utils.CombineHashCode(image.GetHashCode(), Utils.GetNullableHashCode(clearValue));

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}

struct ColorAttachment : this(GpuImage image, Color? clearColor = null), IEquatable<Self>, IHashable {
	public bool Equals(Self other) => image == other.image && clearColor == other.clearColor;

	public int GetHashCode() => Utils.CombineHashCode(image.GetHashCode(), Utils.GetNullableHashCode(clearColor));

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}

class RenderPassBuilder {
	private CommandBuffer cmds;
	private append String name = .();
	
	private DepthAttachment? depthAttachment;
	private append List<ColorAttachment> colorAttachments = .();

	private void Prepare(CommandBuffer cmds, StringView name) {
		this.cmds = cmds;
		this.name.Set(name);

		depthAttachment = null;
		colorAttachments.Clear();
	}

	public Self Depth(GpuImage image, float? clearValue = null) {
		depthAttachment = .(image, clearValue);
		return this;
	}

	public Self Color(GpuImage image, Color? clearValue = null) {
		colorAttachments.Add(.(image, clearValue));
		return this;
	}

	public Result<RenderPass> Begin() => Gfx.RenderPasses.[Friend]Begin();
}

// TODO: Do not create new render pass for matching attachments but different name
class RenderPassManager {
	private FramebufferManager framebuffers = new .() ~ delete _;
	
	private Dictionary<Info, RenderPass> passes = new .() ~ delete _;
	private int totalCount = 0;
	
	private append RenderPassBuilder builder = .();

	private append SimpleBumpAllocator alloc = .();
	private append List<RenderPass> usedPasses = .();
	private append List<Entry> durationEntries = .();
	
	public int FramebufferCount => framebuffers.Count;
	public int Count => passes.Count;

	public Span<Entry> DurationEntries => durationEntries;

	public void Destroy() {
		for (let (info, pass) in passes) {
			info.Dispose();
			delete pass;
		}

		passes.Clear();

		framebuffers.Destroy();
	}

	[Tracy.Profile]
	public void NewFrame() {
		// Set render pass entries
		for (let entry in durationEntries) {
			delete:alloc entry.name;
		}

		durationEntries.Clear();
		alloc.FreeAll();

		for (let pass in usedPasses) {
			durationEntries.Add(.(new:alloc .(pass.Name), pass.Duration));
		}

		usedPasses.Clear();

		// Delete old render passes
		for (let (info, pass) in passes) {
			if (info.HasNoReferences()) {
				info.Dispose();
				delete pass;

				@info.Remove();
			}
		}

		// Call framebuffers new frame
		framebuffers.NewFrame();
	}

	public RenderPassBuilder New(CommandBuffer cmds, StringView name) {
		Debug.Assert(cmds.[Friend]currentPass == null);
		
		return builder..[Friend]Prepare(cmds, name);
	}

	[Tracy.Profile]
	public void End(RenderPass pass) {
		Debug.Assert(pass.Cmds.[Friend]currentPass != null);

		vkCmdEndRenderPass(pass.Cmds.Vk);
		pass.Cmds.EndQuery(pass.[Friend]query);
		pass.Cmds.PopDebugGroup();

		pass.[Friend]cmds = null;
		builder.[Friend]cmds.[Friend]currentPass = null;
		
		if (builder.[Friend]depthAttachment.HasValue) {
			builder.[Friend]depthAttachment.Value.image.[Friend]mipAccesses[0] = .Sample;
		}

		for (let color in builder.[Friend]colorAttachments) {
			color.image.[Friend]mipAccesses[0] = color.image.[Friend]swapchain ? .Present : .Sample;
		}
	}

	[Tracy.Profile]
	private Result<RenderPass> Begin() {
		// Get pass and framebuffer
		RenderPass pass = GetPass().GetOrPropagate!();
		let (framebuffer, size) = GetFramebuffer(pass).GetOrPropagate!();

		// Begin pass
		bool hasDepth = builder.[Friend]depthAttachment.HasValue;
		int count = (hasDepth ? 1 : 0) + builder.[Friend]colorAttachments.Count;

		VkClearValue* clearValues = scope .[count]*;

		if (hasDepth) {
			DepthAttachment depth = builder.[Friend]depthAttachment.Value;

			if (depth.clearValue.HasValue) {
				clearValues[0] = .() {
					depthStencil = .() {
						depth = depth.clearValue.Value
					}
				};
			}
		}

		{
			int i = hasDepth ? 1 : 0;

			for (let color in builder.[Friend]colorAttachments) {
				if (color.clearColor.HasValue) {
					Color value = color.clearColor.Value;

					clearValues[i] = .() {
						color = .() {
							float32 = .(value.R, value.G, value.B, value.A)
						}
					};
				}

				i++;
			}
		}

		VkRenderPassBeginInfo info = .() {
			renderPass = pass.Vk,
			framebuffer = framebuffer,
			renderArea = .(
				0, 0,
				(.) size.x, (.) size.y
			),
			clearValueCount = (.) count,
			pClearValues = clearValues
		};

		builder.[Friend]cmds.PushDebugGroup(builder.[Friend]name);
		builder.[Friend]cmds.BeginQuery(pass.[Friend]query);
		vkCmdBeginRenderPass(builder.[Friend]cmds.Vk, &info, .VK_SUBPASS_CONTENTS_INLINE);

		// Set some state
		pass.[Friend]cmds = builder.[Friend]cmds;
		builder.[Friend]cmds.[Friend]currentPass = pass;

		if (builder.[Friend]depthAttachment.HasValue) {
			builder.[Friend]depthAttachment.Value.image.[Friend]mipAccesses[0] = .DepthAttachment;
		}

		for (let color in builder.[Friend]colorAttachments) {
			color.image.[Friend]mipAccesses[0] = .ColorAttachment;
		}

		pass.[Friend]Prepare();
		usedPasses.Add(pass);

		return pass;
	}

	private Result<(VkFramebuffer, Vec2i)> GetFramebuffer(RenderPass pass) {
		bool hasDepth = builder.[Friend]depthAttachment.HasValue;
		int count = (hasDepth ? 1 : 0) + builder.[Friend]colorAttachments.Count;

		GpuImageView[] attachments = scope .[count];

		Vec2i size = .ZERO;

		mixin Attachment(GpuImage image) {
			if (size.IsZero) {
				size = image.Size;
			}
			else if (size != image.Size) {
				Log.Error("Failed to begin a render pass, all attachments have to be the same size");
				return .Err;
			}

			image.GetView().GetOrPropagate!()
		}

		if (hasDepth) {
			attachments[0] = Attachment!(builder.[Friend]depthAttachment.Value.image);
		}

		{
			int i = hasDepth ? 1 : 0;
	
			for (let color in builder.[Friend]colorAttachments) {
				attachments[i++] = Attachment!(color.image);
			}
		}

		return .Ok((framebuffers.Get(pass, attachments, size), size));
	}

	private Result<RenderPass> GetPass() {
		// Check cache
		Info info = .Point(builder);
		RenderPass pass;

		if (passes.TryGetValue(info, out pass)) {
			return pass;
		}

		// Create pass
		//     Attachments
		bool hasDepth = builder.[Friend]depthAttachment.HasValue;
		int attachmentCount = (hasDepth ? 1 : 0) + builder.[Friend]colorAttachments.Count;

		VkAttachmentDescription* attachments = scope .[attachmentCount]*;

		mixin AttachmentDescription(GpuImage image, bool clear) {
			bool swapchain = image.[Friend]swapchain;

			VkAttachmentDescription() {
				format = image.Format.Vk,
				samples = .VK_SAMPLE_COUNT_1_BIT,
				loadOp = clear ? .VK_ATTACHMENT_LOAD_OP_CLEAR : (swapchain ? .VK_ATTACHMENT_LOAD_OP_DONT_CARE : .VK_ATTACHMENT_LOAD_OP_LOAD),
				storeOp = .VK_ATTACHMENT_STORE_OP_STORE,
				stencilLoadOp = .VK_ATTACHMENT_LOAD_OP_DONT_CARE,
				stencilStoreOp = .VK_ATTACHMENT_STORE_OP_DONT_CARE,
				initialLayout = swapchain ? .VK_IMAGE_LAYOUT_UNDEFINED : image.GetAccess().Vk,
				finalLayout = swapchain ? .VK_IMAGE_LAYOUT_PRESENT_SRC_KHR : .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
			}
		}

		if (hasDepth) {
			DepthAttachment depth = builder.[Friend]depthAttachment.Value;
			attachments[0] = AttachmentDescription!(depth.image, depth.clearValue.HasValue);
		}

		{
			int i = hasDepth ? 1 : 0;

			for (let color in builder.[Friend]colorAttachments) {
				attachments[i++] = AttachmentDescription!(color.image, color.clearColor.HasValue);
			}
		}

		//     Subpasses
		VkAttachmentReference depthRef = .() {
			attachment = 0,
			layout = .VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL
		};

		int colorAttachmentCount = builder.[Friend]colorAttachments.Count;
		VkAttachmentReference* colorAttachments = scope .[colorAttachmentCount]*;

		for (int i < colorAttachmentCount) {
			colorAttachments[i] = .() {
				attachment = (.) ((hasDepth ? 1 : 0) + i),
				layout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
			};
		}

		VkSubpassDescription subpass = .() {
			pipelineBindPoint = .VK_PIPELINE_BIND_POINT_GRAPHICS,
			pDepthStencilAttachment = hasDepth ? &depthRef : null,
			colorAttachmentCount = (.) colorAttachmentCount,
			pColorAttachments = colorAttachments
		};

		//     Render Pass
		VkRenderPassCreateInfo createInfo = .() {
			attachmentCount = (.) attachmentCount,
			pAttachments = attachments,
			subpassCount = 1,
			pSubpasses = &subpass
		};

		VkRenderPass handle = ?;
		VkResult result = vkCreateRenderPass(Gfx.Device, &createInfo, null, &handle);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan render pass: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_RENDER_PASS,
				objectHandle = handle,
				pObjectName = scope $"[RENDER_PASS] {builder.[Friend]name} - {totalCount}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		//     Create and return
		info.AddWeakRef();

		pass = new [Friend].(handle, builder.[Friend]name);
		passes[.Copy(info)] = pass;

		totalCount++;

		return pass;
	}
	
	struct Info : IEquatable<Self>, IHashable, IDisposable {
		private String name;
		private DepthAttachment? depthAttachment;
		private Span<ColorAttachment> colorAttachments;

		private int hash;
		private bool copied;

		private this(String name, DepthAttachment? depthAttachment, Span<ColorAttachment> colorAttachments, bool copied) {
			this.name = name;
			this.depthAttachment = depthAttachment;
			this.colorAttachments = colorAttachments;

			this.hash = Utils.CombineHashCode(Utils.CombineHashCode(name.GetHashCode(), Utils.GetNullableHashCode(depthAttachment)), colorAttachments.GetCombinedHashCode());
			this.copied = copied;
		}

		public static Self Point(RenderPassBuilder builder) => .(builder.[Friend]name, builder.[Friend]depthAttachment, builder.[Friend]colorAttachments, false);

		public static Self Copy(Self info) => .(new .(info.name), info.depthAttachment, info.colorAttachments.Copy(), true);

		public bool HasNoReferences() {
			if (depthAttachment.HasValue && depthAttachment.Value.image.NoReferences) return true;

			for (let color in colorAttachments) {
				if (color.image.NoReferences) return true;
			}

			return false;
		}

		public void AddWeakRef() {
			depthAttachment?.image.AddWeakRef();

			for (let color in colorAttachments) {
				color.image.AddWeakRef();
			}
		}

		public bool Equals(Self other) {
			if (depthAttachment != other.depthAttachment) return false;
			if (colorAttachments.Length != other.colorAttachments.Length) return false;
			if (name != other.name) return false;

			for (int i < colorAttachments.Length) {
				if (colorAttachments[i] != other.colorAttachments[i]) return false;
			}

			return true;
		}

		public int GetHashCode() => hash;

		public void Dispose() {
			depthAttachment?.image.ReleaseWeak();

			for (let color in colorAttachments) {
				color.image.ReleaseWeak();
			}

			if (copied) {
				delete name;
				delete colorAttachments.Ptr;
			}
		}

		public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	}
	
	public struct Entry : this(String name, TimeSpan duration) {}
}