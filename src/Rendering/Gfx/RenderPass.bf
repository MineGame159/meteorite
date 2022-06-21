using System;

using Wgpu;

namespace Meteorite {
	struct RenderPass {
		public static RenderPass Null => .(.Null);

		private Wgpu.RenderPassEncoder encoder;

		private this(Wgpu.RenderPassEncoder encoder) {
			this.encoder = encoder;
		}

		public void End() => encoder.End();

		public void PushDebugGroup(StringView name) => encoder.PushDebugGroup(name.ToScopeCStr!());
		public void PopDebugGroup() => encoder.PopDebugGroup();

		public void SetPushConstants(Wgpu.ShaderStage stages, int offset, int size, void* data) {
			encoder.SetPushConstants(stages, (.) offset, (.) size, data);
		}

		public void Draw(int indexCount) {
			encoder.DrawIndexed((.) indexCount, 1, 0, 0, 0);
		}

		public static RenderPassBuilder Begin(Wgpu.CommandEncoder encoder) => new [Friend].(encoder);
	}

	class RenderPassBuilder {
		struct ColorAttachment : this(Wgpu.TextureView texture, Color? clear) {}
		struct DepthAttachment : this(Wgpu.TextureView texture, float? clear) {}

		private Wgpu.CommandEncoder encoder;

		private ColorAttachment[4] colorAttachments;
		private int colorAttachmentCount;

		private DepthAttachment? depthAttachment;

		private this(Wgpu.CommandEncoder encoder) {
			this.encoder = encoder;
		}

		public Self Color(Wgpu.TextureView texture, Color? clear = null) {
			colorAttachments[colorAttachmentCount++] = .(texture, clear);
			return this;
		}

		public Self Depth(Wgpu.TextureView texture, float? clear = null) {
			depthAttachment = .(texture, clear);
			return this;
		}

		public RenderPass Finish() {
			Wgpu.RenderPassColorAttachment[4] colorDescs = .();

			for (int i < colorAttachmentCount) {
				ColorAttachment attachment = colorAttachments[i];
				ref Wgpu.RenderPassColorAttachment desc = ref colorDescs[i];

				desc.view = attachment.texture;
				desc.loadOp = .Load;
				desc.storeOp = .Store;

				if (attachment.clear.HasValue) {
					Color clear = attachment.clear.Value;

					desc.loadOp = .Clear;
					desc.clearValue = .(clear.R, clear.G, clear.B, clear.A);
				}
			}

			Wgpu.RenderPassDescriptor desc = .() {
				colorAttachmentCount = (.) colorAttachmentCount,
				colorAttachments = &colorDescs
			};

			Wgpu.RenderPassDepthStencilAttachment depthDesc;
			if (depthAttachment.HasValue) {
				DepthAttachment depth = depthAttachment.Value;

				depthDesc = .() {
					view = depth.texture,
					depthLoadOp = .Load,
					depthStoreOp = .Store,
					stencilLoadOp = .Load,
					stencilStoreOp = .Store,
					stencilReadOnly = true,
				};

				if (depth.clear.HasValue) {
					depthDesc.depthLoadOp = .Clear;
					depthDesc.depthClearValue = depth.clear.Value;
				}

				desc.depthStencilAttachment = &depthDesc;
			}

			RenderPass pass = [Friend].(encoder.BeginRenderPass(&desc));

			delete this;
			return pass;
		}
	}
}