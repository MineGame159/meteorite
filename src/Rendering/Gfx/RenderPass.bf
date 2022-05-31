using System;

using Wgpu;

namespace Meteorite {
	enum RenderPassAttachmentType {
		Color,
		Depth
	}

	enum RenderPassAttachmentSize {
		case Screen;
		case Custom(int width, int height);
	}

	class RenderPass {
		private RenderPassAttachment<Color> color ~ if (ownsColor) delete _;
		private bool ownsColor;

		private RenderPassAttachment<float> depth ~ if (ownsDepth) delete _;
		private bool ownsDepth;

		public delegate void(RenderPass) callback ~ delete _;

		private Wgpu.RenderPassEncoder pass;

		private this(RenderPassAttachment<Color> color, bool ownsColor, RenderPassAttachment<float> depth, bool ownsDepth, delegate void(RenderPass) callback) {
			this.color = color;
			this.ownsColor = ownsColor;

			this.depth = depth;
			this.ownsDepth = ownsDepth;

			this.callback = callback;
		}

		public void Render(Wgpu.CommandEncoder encoder, Wgpu.TextureView swapChainView, int screenWidth, int screenHeight) {
			Wgpu.RenderPassColorAttachment colorDesc = .();
			if (color != null) {
				color.Update(screenWidth, screenHeight);

				colorDesc.view = color.colorSwapChain ? swapChainView : color.view;
				colorDesc.loadOp = color.first ? .Clear : .Load;
				colorDesc.storeOp = .Store;
				colorDesc.clearValue = .(color.clearValue.R, color.clearValue.G, color.clearValue.B, color.clearValue.A);

				color.first = false;
			}

			Wgpu.RenderPassDepthStencilAttachment depthDesc = .();
			if (depth != null) {
				depth.Update(screenWidth, screenHeight);

				depthDesc.view = depth.view;
				depthDesc.depthLoadOp = depth.first ? .Clear : .Load;
				depthDesc.depthStoreOp = .Store;
				depthDesc.depthClearValue = depth.clearValue;
				depthDesc.stencilLoadOp = .Load;
				depthDesc.stencilStoreOp = .Store;
				depthDesc.stencilReadOnly = true;

				depth.first = false;
			}

			Wgpu.RenderPassDescriptor passDesc = .() {
				colorAttachmentCount = color != null ? 1 : 0,
				colorAttachments = color != null ? &colorDesc : null,
				depthStencilAttachment = depth != null ? &depthDesc : null
			};

			pass = encoder.BeginRenderPass(&passDesc);
			callback(this);
			pass.End();
		}

		public void AfterRender() {
			if (color != null) color.first = true;
			if (depth != null) depth.first = true;
		}

		public void SetClearColor(Color color) {
			if (this.color != null) this.color.clearValue = color;
		}

		public void PushDebugGroup(StringView name) => pass.PushDebugGroup(name.ToScopeCStr!());
		public void PopDebugGroup() => pass.PopDebugGroup();

		public void SetPushConstants(Wgpu.ShaderStage stages, int offset, int size, void* data) {
			pass.SetPushConstants(stages, (.) offset, (.) size, data);
		}

		public void Draw(int indexCount) {
			pass.DrawIndexed((.) indexCount, 1, 0, 0, 0);
		}

		public static operator Wgpu.RenderPassEncoder(RenderPass pass) => pass.pass;
	}

	class RenderPassAttachment<T> where T : struct {
		public RenderPassAttachmentType type;
		public RenderPassAttachmentSize size;
		public T clearValue;

		public bool colorSwapChain;
		public bool first = true;

		public Texture texture ~ delete _;
		public Wgpu.TextureView view = .Null ~ if (view != .Null) _.Drop();

		private int currentWidth, currentHeight;

		public this(RenderPassAttachmentType type, RenderPassAttachmentSize size, T clearValue, bool colorSwapChain) {
			this.type = type;
			this.size = size;
			this.clearValue = clearValue;
			this.colorSwapChain = colorSwapChain;
		}

		public void Update(int screenWidth, int screenHeight) {
			if (type == .Color && colorSwapChain) return;

			if (size case .Custom(let width, let height)) {
				if (texture == null) {
					texture = Gfx.CreateTexture(.RenderAttachment, width, height, 1, null, type == .Color ? .RGBA8Unorm : .Depth32Float);
					view = texture.CreateView();
				}
				return;
			}

			if (currentWidth != screenWidth || currentHeight != screenHeight) {
				if (texture != null) {
					view.Drop();
					delete texture;
				}

				texture = Gfx.CreateTexture(.RenderAttachment, screenWidth, screenHeight, 1, null, type == .Color ? .RGBA8Unorm : .Depth32Float);
				view = texture.CreateView();

				currentWidth = screenWidth;
				currentHeight = screenHeight;
			}
		}
	}

	class RenderPassBuilder {
		private delegate void(RenderPass) callback;

		private bool hasColor;
		private RenderPassAttachmentSize colorSize;
		private Color clearColor;
		private bool colorSwapChain;
		private RenderPass colorPass;

		private bool hasDepth;
		private RenderPassAttachmentSize depthSize;
		private float clearDepth;
		private RenderPass depthPass;

		private this() {}

		public RenderPassBuilder Callback(delegate void(RenderPass) callback) {
			this.callback = callback;

			return this;
		}

		public RenderPassBuilder Color(RenderPassAttachmentSize size, Color clearColor, bool swapChain = false) {
			this.hasColor = true;
			this.colorSize = size;
			this.clearColor = clearColor;
			this.colorSwapChain = swapChain;

			return this;
		}

		public RenderPassBuilder Color(RenderPass pass) {
			this.hasColor = true;
			this.colorPass = pass;

			return this;
		}

		public RenderPassBuilder Depth(RenderPassAttachmentSize size, float clearValue) {
			this.hasDepth = true;
			this.depthSize = size;
			this.clearDepth = clearValue;

			return this;
		}

		public RenderPassBuilder Depth(RenderPass pass) {
			this.hasDepth = true;
			this.depthPass = pass;

			return this;
		}

		public RenderPass Create() {
			RenderPassAttachment<Color> color = null;
			bool ownsColor = false;

			if (hasColor) {
				if (colorPass != null) color = colorPass.[Friend]color;
				else {
					color = new .(.Color, colorSize, clearColor, colorSwapChain);
					ownsColor = true;
				}
			}

			RenderPassAttachment<float> depth = null;
			bool ownsDepth = false;

			if (hasDepth) {
				if (depthPass != null) depth = depthPass.[Friend]depth;
				else {
					depth = new .(.Depth, depthSize, clearDepth, false);
					ownsDepth = true;
				}
			}

			RenderPass pass = new [Friend].(color, ownsColor, depth, ownsDepth, callback);
			delete this;
			return pass;
		}
	}
}