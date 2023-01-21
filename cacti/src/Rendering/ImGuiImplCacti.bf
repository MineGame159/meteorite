using System;

using ImGui;
using Bulkan;

namespace Cacti {
	static class ImGuiImplCacti {
		class Data {
			public Pipeline pipeline;
			public DescriptorSet set ~ delete _;
			public GpuImage fontImage ~ delete _;
		}

		private static Data _;

		public static void Init() {
			ImGui.IO* io = ImGui.GetIO();

			Data data = new .();
			_ = data; // For some reason the GC is detecting it as a memory leak

			io.BackendRendererUserData = Internal.UnsafeCastToPtr(data);
			io.BackendRendererName = "imgui_impl_cacti";
			io.BackendFlags |= .RendererHasVtxOffset;

			CreateObjects();
		}

		public static void Shutdown() {
			delete GetData();
		}

		public static void NewFrame() {}

		private static bool firstFrame = true;

		public static CommandBuffer Render(GpuImage target, ImGui.DrawData* drawData) {
			Data data = GetData();

			ImGui.Vec2 prevSize = drawData.DisplaySize;

			if (ImGuiCacti.customSize) {
				drawData.DisplaySize = .(ImGuiCacti.size.x, ImGuiCacti.size.y);
			}

			defer {
				drawData.DisplaySize = prevSize;
			}

			// Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
			int fbWidth = (int)(drawData.DisplaySize.x * drawData.FramebufferScale.x);
			int fbHeight = (int)(drawData.DisplaySize.y * drawData.FramebufferScale.y);
			if (fbWidth <= 0 || fbHeight <= 0) return null;

			if (drawData.CmdListsCount == 0) return null;

			// Begin command buffer
			CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
			cmds.Begin();
			cmds.PushDebugGroup("ImGui");
			cmds.SetViewport(target.size, false, true);

			if (firstFrame) {
				firstFrame = false;
				cmds.TransitionImage(data.fontImage, .Sample);
			}

			if (drawData.CmdListsCount > 0) {
				cmds.BeginPass(null, .(target, null));

				// Upload vertex and index data
				uint64 vertexSize = (.) drawData.TotalVtxCount * sizeof(ImGui.DrawVert);
				uint64 indexSize = (.) drawData.TotalIdxCount * sizeof(ImGui.DrawIdx);

				GpuBufferView vertexBuffer = Gfx.FrameAllocator.Allocate(.Vertex, vertexSize);
				GpuBufferView indexBuffer = Gfx.FrameAllocator.Allocate(.Index, indexSize);

				ImGui.DrawVert* vertexData = (.) vertexBuffer.Map();
				ImGui.DrawIdx* indexData = (.) indexBuffer.Map();

				for (int i < drawData.CmdListsCount) {
					ImGui.DrawList* cmdList = drawData.CmdLists[i];

					Internal.MemCpy(vertexData, cmdList.VtxBuffer.Data, cmdList.VtxBuffer.Size * sizeof(ImGui.DrawVert));
					Internal.MemCpy(indexData, cmdList.IdxBuffer.Data, cmdList.IdxBuffer.Size * sizeof(ImGui.DrawIdx));

					vertexData += cmdList.VtxBuffer.Size;
					indexData += cmdList.IdxBuffer.Size;
				}

				indexBuffer.Unmap();
				vertexBuffer.Unmap();

				// Setup render state
				void SetupRenderState() {
					cmds.Bind(data.pipeline);
					cmds.Bind(vertexBuffer);
					cmds.Bind(indexBuffer, sizeof(ImGui.DrawIdx) == 2 ? .Uint16 : .Uint32);

					float[4] scaleTranslate;
					scaleTranslate[0] = 2.0f / drawData.DisplaySize.x;
					scaleTranslate[1] = 2.0f / drawData.DisplaySize.y;
					scaleTranslate[2] = -1.0f - drawData.DisplayPos.x * scaleTranslate[0];
					scaleTranslate[3] = -1.0f - drawData.DisplayPos.y * scaleTranslate[1];
					cmds.SetPushConstants(scaleTranslate);
				}

				SetupRenderState();

				// Will project scissor/clipping rectangles into framebuffer space
				ImGui.Vec2 clipOff = drawData.DisplayPos;         // (0,0) unless using multi-viewports
				ImGui.Vec2 clipScale = drawData.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

				// Render command lists
				int globalVtxOffset = 0;
				int globalIdxOffset = 0;

				for (int i < drawData.CmdListsCount) {
					ImGui.DrawList* cmdList = drawData.CmdLists[i];

					for (int j < cmdList.CmdBuffer.Size) {
						ImGui.DrawCmd* cmd = &cmdList.CmdBuffer.Data[j];

						if (cmd.UserCallback != null) {
						    // User callback, registered via ImDrawList::AddCallback()
						    // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
#unwarn
						    if (cmd.UserCallback == *ImGui.DrawCallback_ResetRenderState) SetupRenderState();
						    else cmd.UserCallback(cmdList, cmd);
						}
						else {
							// Project scissor/clipping rectangles into framebuffer space
							ImGui.Vec2 clipMin = .((cmd.ClipRect.x - clipOff.x) * clipScale.x, (cmd.ClipRect.y - clipOff.y) * clipScale.y);
							ImGui.Vec2 clipMax = .((cmd.ClipRect.z - clipOff.x) * clipScale.x, (cmd.ClipRect.w - clipOff.y) * clipScale.y);

							// Clamp to viewport as vkCmdSetScissor() won't accept values that are off bounds
							if (clipMin.x < 0.0f) clipMin.x = 0.0f;
							if (clipMin.y < 0.0f) clipMin.y = 0.0f;
							if (clipMax.x > fbWidth) clipMax.x = fbWidth;
							if (clipMax.y > fbHeight) clipMax.y = fbHeight;
							if (clipMax.x <= clipMin.x || clipMax.y <= clipMin.y) continue;

							// Apply scissor/clipping rectangle
							cmds.SetScissor(.((.) clipMin.x, (.) clipMin.y), .((.) (clipMax.x - clipMin.x), (.) (clipMax.y - clipMin.y)));

							// Bind DescriptorSet with font or user texture
							VkDescriptorSet[1] descSet = .( *(VkDescriptorSet*) cmd.TextureId );
							if (sizeof(ImGui.TextureID) < sizeof(ImGui.U64)) {
							    // We don't support texture switches if ImTextureID hasn't been redefined to be 64-bit. Do a flaky check that other textures haven't been used.
							    System.Diagnostics.Debug.Assert(cmd.TextureId == (ImGui.TextureID) &data.set);
							    descSet[0] = data.set.[Friend]handle;
							}
							VulkanNative.vkCmdBindDescriptorSets(cmds.[Friend]handle, .VK_PIPELINE_BIND_POINT_GRAPHICS, data.pipeline.Layout, 0, 1, &descSet, 0, null);

							// Draw
							cmds.DrawIndexed(cmd.ElemCount, (.) (cmd.IdxOffset + globalIdxOffset), (.) (cmd.VtxOffset + globalVtxOffset));
						}
					}

					globalIdxOffset += cmdList.IdxBuffer.Size;
					globalVtxOffset += cmdList.VtxBuffer.Size;
				}
			}

			// End render pass
			if (drawData.CmdListsCount > 0) cmds.EndPass();

			// End command buffer
			cmds.PopDebugGroup();
			cmds.End();

			return cmds;
		}

		public static void CreateFontsTexture() {
			Data data = GetData();
			ImGui.IO* io = ImGui.GetIO();

			uint8* pixels = ?;
			int32 width, height;
			io.Fonts.GetTexDataAsRGBA32(out pixels, out width, out height);

			data.fontImage = Gfx.Images.Create(.RGBA, .Normal, .(width, height), "ImGui - Font");
			Gfx.Uploads.UploadImage(data.fontImage, pixels);
			
			data.set = Gfx.DescriptorSets.Create(Gfx.DescriptorSetLayouts.Get(.SampledImage), .SampledImage(data.fontImage, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfx.Samplers.Get(.Linear, .Linear)));

			io.Fonts.SetTexID((ImGui.TextureID) &data.set.[Friend]handle);
		}

		private static Data GetData() {
		    return ImGui.GetCurrentContext() != null ? (.) Internal.UnsafeCastToObject(ImGui.GetIO().BackendRendererUserData) : null;
		}

		private static void CreateObjects() {
			Data data = GetData();

			// Pipeline
			data.pipeline = Gfx.Pipelines.Get(scope PipelineInfo("ImGui")
				.VertexFormat(scope VertexFormat().Attribute(.Float, 2).Attribute(.Float, 2).Attribute(.U8, 4, true))
				.Shader(VERTEX_SHADER, FRAGMENT_SHADER, null, false)
				.Sets(Gfx.DescriptorSetLayouts.Get(.SampledImage))
				.PushConstants<float[4]>()
				.Cull(.None, .Clockwise)
				.Targets(
					.(.BGRA, .Default())
				)
			);
		}

		private const StringView VERTEX_SHADER = """
			#version 450

			layout (location = 0) in vec2 aPos;
			layout (location = 1) in vec2 aUV;
			layout (location = 2) in vec4 aColor;

			layout (push_constant) uniform uPushConstant {
			    vec2 uScale;
			    vec2 uTranslate;
			} pc;

			out gl_PerVertex {
			    vec4 gl_Position;
			};

			layout (location = 0) out struct {
			    vec4 Color;
			    vec2 UV;
			} Out;

			void main() {
			    Out.Color = aColor;
			    Out.UV = aUV;
			    gl_Position = vec4(aPos * pc.uScale + pc.uTranslate, 0, 1);
			}
			""";

		private const StringView FRAGMENT_SHADER = """
			#version 450
			
			layout (location = 0) out vec4 fColor;

			layout (set = 0, binding = 0) uniform sampler2D sTexture;

			layout (location = 0) in struct {
			    vec4 Color;
			    vec2 UV;
			} In;

			void main() {
			    fColor = In.Color * texture(sTexture, In.UV.st);
			}
			""";
	}
}