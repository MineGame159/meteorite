using System;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class RenderPass : IDisposable {
	// Fields

	private VkRenderPass handle ~ vkDestroyRenderPass(Gfx.Device, _, null);

	private append String name = .();
	private append GpuQuery query = .();

	private CommandBuffer cmds;

	private Vec2i viewport;
	private RenderPass currentPass;
	private Pipeline boundPipeline;

	private GpuBufferView boundVbo, boundIbo;

	// Properties

	public VkRenderPass Vk => handle;

	public StringView Name => name;
	public TimeSpan Duration => query.Duration;

	public CommandBuffer Cmds => cmds;

	// Constructors / Destructors

	private this(VkRenderPass handle, StringView name) {
		this.handle = handle;
		this.name.Set(name);
	}

	// Render Pass

	private void Prepare() {
		boundPipeline = null;

		boundVbo = default;
		boundIbo = default;
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

		vkCmdSetViewport(cmds.Vk, 0, 1, &info);
		viewport = size;
		
		if (scissor) SetScissor(.(), size);
	}

	public void SetScissor(Vec2i pos, Vec2i size) {
		VkRect2D info = .() {
			offset = .((.) pos.x, (.) pos.y),
			extent = .((.) size.x, (.) size.y)
		};

		vkCmdSetScissor(cmds.Vk, 0, 1, &info);
	}

	public void Bind(Pipeline pipeline) {
		if (boundPipeline == pipeline) return;

		vkCmdBindPipeline(cmds.Vk, .VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline.GetVk(cmds.[Friend]currentPass));
		boundPipeline = pipeline;
	}

	public Result<void> Bind(int setIndex, params Descriptor[] descriptors) {
		// Transition images
		for (let descriptor in descriptors) {
			if (descriptor.Type == .SampledImage) {
				cmds.TransitionImage(descriptor.Image.image, .Sample);
			}
		}

		// Bind
		VkDescriptorSet set = Gfx.DescriptorSets.Get(descriptors).GetOrPropagate!();
		vkCmdBindDescriptorSets(cmds.Vk, .VK_PIPELINE_BIND_POINT_GRAPHICS, boundPipeline.Layout, (.) setIndex, 1, &set, 0, null);

		return .Ok;
	}

	public void Bind(GpuBufferView view, IndexType indexType = .Uint32) {
		var view;

		switch (view.buffer.Type) {
		case .Vertex:
			if (boundVbo != view) {
				vkCmdBindVertexBuffers(cmds.Vk, 0, 1, &view.buffer.[Friend]handle, &view.offset);
				boundVbo = view;
			}

		case .Index:
			if (boundIbo != view) {
				vkCmdBindIndexBuffer(cmds.Vk, view.buffer.[Friend]handle, view.offset, indexType.Vk);
				boundIbo = view;
			}

		default:
			Log.Error("{} buffer cannot be bound to a command buffer", view.buffer.Type);
		}
	}

	public void SetPushConstants(void* value, uint32 size) {
		Debug.Assert(size <= boundPipeline.[Friend]shaderInfo.PushConstantSize);
		vkCmdPushConstants(cmds.Vk, boundPipeline.Layout, .VK_SHADER_STAGE_VERTEX_BIT | .VK_SHADER_STAGE_FRAGMENT_BIT, 0, size, value);
	}

	public void SetPushConstants<T>(T value) {
		var value;
		SetPushConstants(&value, (.) sizeof(T));
	}

	public void DrawIndexed(uint32 indexCount, uint32 firstIndex = 0, int32 vertexOffset = 0) {
		vkCmdDrawIndexed(cmds.Vk, indexCount, 1, firstIndex, vertexOffset, 0);
	}

	public void Draw(BuiltMesh mesh) {
		if (mesh.indexCount == 0 || !mesh.vbo.Valid || !mesh.ibo.Valid) return;

		Bind(mesh.vbo);
		Bind(mesh.ibo);
		DrawIndexed(mesh.indexCount);
	}

	public void PushDebugGroup(StringView name, Color color = .BLACK) => cmds.PushDebugGroup(name, color);
	public void PopDebugGroup() => cmds.PopDebugGroup();

	public void Dispose() {
		Gfx.RenderPasses.End(this);
	}
}