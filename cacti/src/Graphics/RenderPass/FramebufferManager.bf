using System;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class FramebufferManager {
	private Dictionary<Layout, Dictionary<Info, VkFramebuffer>> cache = new .() ~ delete _;
	private int count;

	public int Count => count;

	public void Destroy() {
		for (let (layout, framebuffers) in cache) {
			for (let (info, framebuffer) in framebuffers) {
				info.Dispose();
				vkDestroyFramebuffer(Gfx.Device, framebuffer, null);
			}

			layout.Dispose();
			delete framebuffers;
		}

		cache.Clear();
		count = 0;
	}

	public void NewFrame() {
		// Destroy framebuffers pointing to attachments that are about to be deleted
		for (let framebuffers in cache.Values) {
			for (var (info, framebuffer) in framebuffers) {
				// Check if the framebuffer contains an attachment that has only one reference
				bool destroy = false;
	
				for (let attachment in info) {
					if (attachment.Image.NoReferences) {
						destroy = true;
						break;
					}
				}
	
				// Destroy framebuffer
				if (destroy) {
					info.Dispose();
					vkDestroyFramebuffer(Gfx.Device, framebuffer, null);
	
					@info.Remove();
					count--;
				}
			}
		}
	}

	public Result<VkFramebuffer> Get(RenderPass renderPass, GpuImageView[] attachments, Vec2i size) {
		// Get layout and info
		ImageFormat[] formats = scope .[attachments.Count];

		for (int i < attachments.Count) {
			formats[i] = attachments[i].Image.Format;
		}

		Layout layout = .Point(formats);
		Info info = .Point(attachments, size);

		// Get cache for the layout
		Dictionary<Info, VkFramebuffer> framebuffers;
		
		if (!cache.TryGetValue(layout, out framebuffers)) {
			framebuffers = new .();
			cache[.Copy(layout)] = framebuffers;
		}

		// Check cache
		VkFramebuffer framebuffer;

		if (framebuffers.TryGetValue(info, out framebuffer)) {
			return framebuffer;
		}

		// Create framebuffer
		VkImageView* rawAttachments = scope .[attachments.Count]*;

		for (int i < attachments.Count) {
			rawAttachments[i] = attachments[i].Vk;
			attachments[i].Image.AddWeakRef();
		}

		VkFramebufferCreateInfo createInfo = .() {
			renderPass = renderPass.Vk,
			attachmentCount = (.) attachments.Count,
			pAttachments = rawAttachments,
			width = (.) size.x,
			height = (.) size.y,
			layers = 1
		};

		VkResult result = vkCreateFramebuffer(Gfx.Device, &createInfo, null, &framebuffer);
		if (result != .VK_SUCCESS) {
			Log.Error("Failed to create Vulkan framebuffer: {}", result);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_FRAMEBUFFER,
				objectHandle = framebuffer,
				pObjectName = scope $"[FRAMEBUFFER] {count}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		framebuffers[.Copy(info)] = framebuffer;
		count++;
		
		return framebuffer;
	}

	struct Layout : IEquatable<Self>, IHashable, IDisposable {
		private Span<ImageFormat> formats;
		
		private int hash;
		private bool copied;

		private this(Span<ImageFormat> formats, bool copied) {
			this.formats = formats;

			this.hash = formats.GetCombinedHashCode();
			this.copied = copied;
		}

		public static Self Point(Span<ImageFormat> formats) => .(formats, false);

		public static Self Copy(Self layout) => .(layout.formats.Copy(), true);

		public bool Equals(Self other) {
			if (formats.Length != other.formats.Length) return false;

			for (int i < formats.Length) {
				if (formats[i] != other.formats[i]) return false;
			}

			return true;
		}

		public int GetHashCode() => hash;

		public void Dispose() {
			if (copied) {
				delete formats.Ptr;
			}
		}
		
		[Commutable]
		public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	}

	struct Info : IEnumerable<GpuImageView>, IEquatable<Self>, IHashable, IDisposable {
		private Span<GpuImageView> attachments;
		private Vec2i size;

		private int hash;
		private bool copied;

		private this(Span<GpuImageView> attachments, Vec2i size, bool copied) {
			this.attachments = attachments;
			this.size = size;

			this.hash = attachments.GetCombinedHashCode();
			this.copied = copied;

			this.hash = Utils.CombineHashCode(this.hash, size.GetHashCode());
		}

		public static Self Point(Span<GpuImageView> attachments, Vec2i size) => .(attachments, size, false);

		public static Self Copy(Self info) => .(info.attachments.Copy(), info.size, true);

		public Span<GpuImageView>.Enumerator GetEnumerator() => attachments.GetEnumerator();

		public bool Equals(Self other) {
			if (attachments.Length != other.attachments.Length) return false;
			if (size != other.size) return false;

			for (int i < attachments.Length) {
				if (attachments[i] != other.attachments[i]) return false;
			}

			return true;
		}

		public int GetHashCode() => hash;

		public void Dispose() {
			for (let attachment in attachments) {
				attachment.Image.ReleaseWeak();
			}

			if (copied) {
				delete attachments.Ptr;
			}
		}

		[Commutable]
		public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	}
}