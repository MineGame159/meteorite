using System;
using System.IO;

using Wgpu;
using ImGui;

namespace Meteorite {
	class Sampler {
		private Wgpu.Sampler handle ~ _.Drop();

		private this(Wgpu.Sampler handle) {
			this.handle = handle;
		}
	}

	class Shader {
		private Wgpu.ShaderModule handle ~ _.Drop();

		private this(Wgpu.ShaderModule handle) {
			this.handle = handle;
		}
	}

	class WBuffer {
		private Wgpu.Buffer handle ~ _.Drop();
		private Wgpu.BufferUsage usage;

		public readonly uint64 size;

		private this(Wgpu.Buffer handle, Wgpu.BufferUsage usage, uint64 size) {
			this.handle = handle;
			this.usage = usage;
			this.size = size;

			Gfx.ALLOCATED += size;
		}

		public ~this() {
			Gfx.ALLOCATED -= size;
		}

		public void Bind() {
			if (usage.HasFlag(.Vertex)) Gfx.[Friend]pass.SetVertexBuffer(0, handle, 0, 0);
			else if (usage.HasFlag(.Index)) Gfx.[Friend]pass.SetIndexBuffer(handle, .Uint32, 0, 0);
            else {
				Log.Error("Unknown buffer type: {}", usage);
				Runtime.NotImplemented();
			}
		}

		public void Write(void* data, int size) {
			Gfx.[Friend]queue.WriteBuffer(handle, 0, data, (.) size);
		}
	}

	class Texture {
		private Wgpu.Texture handle ~ _.Drop();
		private Wgpu.TextureView view ~ _.Drop();
		private Wgpu.TextureDescriptor descriptor;

		private this(Wgpu.Texture handle, Wgpu.TextureView view, Wgpu.TextureDescriptor descriptor) {
			this.handle = handle;
			this.view = view;
			this.descriptor = descriptor;

			
			Gfx.ALLOCATED += GetUsedMemory();
		}

		public ~this() {
			Gfx.ALLOCATED -= GetUsedMemory();
		}

		public uint64 GetUsedMemory() {
			// Most probably incorrect
			Wgpu.Extent3D s = descriptor.size.GetPhysicalSize(descriptor.format);
			return s.width * s.height * s.depthOrArrayLayers * Wgpu.Describe(descriptor.format).blockSize;
		}

		public Wgpu.TextureView CreateView() {
			Wgpu.TextureViewDescriptor desc = .();
			return handle.CreateView(&desc);
		}

		public void Write(int width, int height, int level, void* data) {
			Wgpu.TextureFormatInfo formatInfo = Wgpu.Describe(descriptor.format);
			Wgpu.Extent3D mipSize = descriptor.GetMipLevelSize((.) level);
			Wgpu.Extent3D mipPhysical = mipSize.GetPhysicalSize(descriptor.format);

			uint32 widthBlocks = mipPhysical.width / formatInfo.blockDimensions[0];
			uint32 heightBlocks = mipPhysical.height / formatInfo.blockDimensions[1];

			uint32 bytesPerRow = widthBlocks * formatInfo.blockSize;

			Wgpu.ImageCopyTexture destination = .() {
				texture = handle,
				mipLevel = (.) level,
				origin = .(0, 0, 0),
				aspect = .All
			};
			Wgpu.TextureDataLayout dataLayout = .() {
				offset = 0,
				bytesPerRow = bytesPerRow,
				rowsPerImage = heightBlocks
			};
			Wgpu.Extent3D size = .((.) width, (.) height, 1);
			Gfx.[Friend]queue.WriteTexture(&destination, data, (.) (width * height * 4), &dataLayout, &size);
		}
	}

	static class Gfx {
		private static Wgpu.Surface surface;
		private static Wgpu.Device device;
		private static Wgpu.SwapChain swapChain;
		private static Wgpu.Queue queue;

		private static Wgpu.TextureView view;
		private static Wgpu.CommandEncoder encoder;
		private static Wgpu.RenderPassEncoder pass;

		private static Wgpu.Texture depthTexture;
		private static Wgpu.TextureView depthView;
		private static Wgpu.Sampler depthSampler;

		public static uint64 ALLOCATED = 0;

		private static bool afterScreenshot = false;

		public static void Init(Window window, Wgpu.Surface surface, Wgpu.Device device, int width, int height) {
			Gfx.surface = surface;
			Gfx.device = device;
			Gfx.swapChain = swapChain;
			Gfx.queue = device.GetQueue();

			// Swap chain
			CreateSwapChain(width, height);

			// Depth texture
			CreateDepthTexture(width, height);

			Wgpu.SamplerDescriptor samplerDesc = .() {
				addressModeU = .ClampToEdge,
				addressModeV = .ClampToEdge,
				addressModeW = .ClampToEdge,
				magFilter = .Linear,
				minFilter = .Linear,
				mipmapFilter = .Nearest,
				compare = .LessEqual,
				lodMinClamp = -100,
				lodMaxClamp = 100
			};
			depthSampler = device.CreateSampler(&samplerDesc);

			// ImGui
			ImGui.CHECKVERSION();
			ImGui.CreateContext();
			ImGui.StyleColorsDark();
			ImGui.GetStyle().Alpha = 0.9f;
			ImGuiImplGlfw.InitForOther(window.handle, true);
			ImGuiImplWgpu.Init(device, 3, .BGRA8Unorm);
		}

		private static void CreateSwapChain(int width, int height) {
			Wgpu.SwapChainDescriptor swapChainDesc = .() {
				usage = .RenderAttachment,
				format = .BGRA8Unorm,
				width = (.) width,
				height = (.) height,
				presentMode = .Fifo
			};
			swapChain = device.CreateSwapChain(surface, &swapChainDesc);
		}

		private static void CreateDepthTexture(int width, int height) {
			Wgpu.Extent3D size = .((.) width, (.) height, 1);
			Wgpu.TextureDescriptor textureDesc = .() {
				label = "Depth",
				size = size,
				mipLevelCount = 1,
				sampleCount = 1,
				dimension = ._2D,
				format = .Depth32Float,
				usage = .RenderAttachment | .TextureBinding
			};
			depthTexture = device.CreateTexture(&textureDesc);

			Wgpu.TextureViewDescriptor viewDesc = .();
			depthView = depthTexture.CreateView(&viewDesc);
		}

		public static void Shutdown() {
			// ImGui
			ImGuiImplWgpu.Shutdown();
			ImGuiImplGlfw.Shutdown();
			ImGui.DestroyContext();
		}

		public static void BeginFrame() {
			Wgpu.CommandEncoderDescriptor encoderDesc = .();

			if (Screenshots.rendering) view = Screenshots.texture.CreateView();
			else view = swapChain.GetCurrentTextureView();

			encoder = device.CreateCommandEncoder(&encoderDesc);

			Wgpu.RenderPassColorAttachment colorDesc = .() {
				view = view,
				loadOp = .Clear,
				storeOp = .Store,
				clearValue = .(0.8, 0.8, 0.8, 1)
			};
			Wgpu.RenderPassDepthStencilAttachment depthDesc = .() {
				view = depthView,
				depthLoadOp = .Clear,
				depthStoreOp = .Store,
				depthClearValue = 1,
				stencilLoadOp = .Load,
				stencilStoreOp = .Store,
				stencilReadOnly = true
			};
			Wgpu.RenderPassDescriptor passDesc = .() {
				label = "Main",
				colorAttachmentCount = 1,
				colorAttachments = &colorDesc,
				depthStencilAttachment = &depthDesc
			};
			pass = encoder.BeginRenderPass(&passDesc);
			pass.PushDebugGroup("Main");

			// ImGui
			ImGuiImplWgpu.NewFrame();
			ImGuiImplGlfw.NewFrame();
			ImGui.NewFrame();
		}

		public static void PushDebugGroup(StringView name) => pass.PushDebugGroup(name.ToScopeCStr!());
		public static void PopDebugGroup() => pass.PopDebugGroup();

		public static void EndFrame() {
			// Submit
			pass.PopDebugGroup();
			pass.End();

			// ImGui
			ImGui.Render();
			if (!Screenshots.rendering || Screenshots.includeGui) {
				Wgpu.RenderPassColorAttachment colorDesc = .() {
					view = view,
					loadOp = .Load,
					storeOp = .Store
				};
				Wgpu.RenderPassDescriptor passDesc = .() {
					label = "ImGui",
					colorAttachmentCount = 1,
					colorAttachments = &colorDesc
				};
				Wgpu.RenderPassEncoder guiPass = encoder.BeginRenderPass(&passDesc);
				guiPass.PushDebugGroup("ImGui");
				ImGuiImplWgpu.RenderDrawData(ImGui.GetDrawData(), guiPass);
				guiPass.PopDebugGroup();
				guiPass.End();
			}

			if (afterScreenshot) {
				Screenshots.AfterRender(encoder);
			}

			// Submit
			Wgpu.CommandBufferDescriptor cbDesc = .();
			Wgpu.CommandBuffer cb = encoder.Finish(&cbDesc);
			queue.Submit(1, &cb);

			if (!Screenshots.rendering) swapChain.Present();
			view.Drop();

			if (afterScreenshot) {
				afterScreenshot = false;
				Screenshots.AfterRender2();
			}

			if (Screenshots.rendering) {
				afterScreenshot = true;
				Screenshots.rendering = false;

				CreateDepthTexture(Screenshots.originalWidth, Screenshots.originalHeight);
			}
		}

		public static BindGroupLayoutBuilder NewBindGroupLayout() => new [Friend].();

		public static Sampler CreateSampler(Wgpu.AddressMode addressMode, Wgpu.FilterMode magFilter, Wgpu.FilterMode minFilter, Wgpu.MipmapFilterMode mipmapFilter = .Nearest, int mipLevels = 1) {
			Wgpu.SamplerDescriptor desc = .() {
				addressModeU = addressMode,
				addressModeV = addressMode,
				addressModeW = addressMode,
				magFilter = magFilter,
				minFilter = minFilter,
				mipmapFilter = mipmapFilter,
				lodMaxClamp = mipLevels
			};

			return new [Friend].(device.CreateSampler(&desc));
		}

		public static Shader CreateShader(StringView path) {
			String buffer = new .();
			File.ReadAllText(path, buffer);

			Wgpu.ShaderModuleWGSLDescriptor wgslDesc = .() {
				chain = .() {
					sType = .ShaderModuleWGSLDescriptor
				},
				code = buffer.CStr()
			};
			Wgpu.ShaderModuleDescriptor desc = .() {
				nextInChain = (Wgpu.ChainedStruct*) &wgslDesc,
			};

			Wgpu.ShaderModule shader = device.CreateShaderModule(&desc);
			delete buffer;

			return new [Friend].(shader);
		}

		public static PipelineBuilder NewPipeline() => new [Friend].();

		public static WBuffer CreateBuffer(Wgpu.BufferUsage usage, int size, void* data = null) {
			uint64 alignedSize = Wgpu.AlignBufferSize!((uint64) size);

			Wgpu.BufferDescriptor desc = .() {
				size = alignedSize,
				usage = usage,
				mappedAtCreation = data != null
			};
			Wgpu.Buffer handle = device.CreateBuffer(&desc);

			if (data != null) {
				void* ptr = handle.GetMappedRange(0, alignedSize);
				Internal.MemCpy(ptr, data, (.) size);
				handle.Unmap();
			}
			
			return new [Friend].(handle, usage, alignedSize);
		}

		public static Texture CreateTexture(Wgpu.TextureUsage usage, int width, int height, int levels, void* data, Wgpu.TextureFormat format = .RGBA8Unorm) {
			Wgpu.TextureDescriptor desc = .() {
				usage = usage,
				dimension = ._2D,
				size = .((.) width, (.) height, 1),
				format = format,
				mipLevelCount = (.) levels,
				sampleCount = 1
			};
			
			Wgpu.Texture handle = data == null ? device.CreateTexture(&desc) : device.CreateTextureWithData(queue, &desc, data);

			Wgpu.TextureViewDescriptor viewDesc = .();
			Wgpu.TextureView view = handle.CreateView(&viewDesc);

			return new [Friend].(handle, view, desc);
		}

		public static void SetPushConstants(Wgpu.ShaderStage stages, int offset, int size, void* data) {
			pass.SetPushConstants(stages, (.) offset, (.) size, data);
		}

		public static void Draw(int indexCount) {
			pass.DrawIndexed((.) indexCount, 1, 0, 0, 0);
		}

		// Internal

		private static Wgpu.BindGroupLayout CreateBindGroupLayout(Span<Wgpu.BindGroupLayoutEntry> entries) {
			Wgpu.BindGroupLayoutDescriptor desc = .() {
				entryCount = (.) entries.Length,
				entries = &entries[0]
			};

			return device.CreateBindGroupLayout(&desc);
		}

		private static Wgpu.BindGroup CreateBindGroup(Wgpu.BindGroupLayout layout, Wgpu.BindGroupEntry[] entries) {
			Wgpu.BindGroupDescriptor desc = .() {
				layout = layout,
				entryCount = (.) entries.Count,
				entries = &entries[0]
			};

			return device.CreateBindGroup(&desc);
		}

		private static Wgpu.RenderPipeline CreatePipeline(Wgpu.PipelineLayoutDescriptor* layoutDesc, Wgpu.RenderPipelineDescriptor* desc) {
			desc.layout = device.CreatePipelineLayout(layoutDesc); // TODO: Maybe drop pipeline layout after pipeline creation
			return device.CreateRenderPipeline(desc);
		}
	}
}