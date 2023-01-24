using System;
using System.Diagnostics;

using ImGui;
using GLFW;
using Bulkan;

namespace Cacti {
	static class ImGuiImplCacti {
		class Data {
			// Platform
			public Window window;
			public GlfwCursor*[(.) ImGui.MouseCursor.COUNT] cursors;
			public double time;

			// Renderer
			public Pipeline pipeline;
			public DescriptorSet set ~ delete _;
			public GpuImage fontImage ~ delete _;

			public ~this() {
				for (let cursor in cursors) {
					Glfw.DestroyCursor(cursor);
				}
			}
		}

		private static Data _;

		public static void Init(Window window) {
			ImGui.IO* io = ImGui.GetIO();

			Data data = new .();
			_ = data; // For some reason the GC is detecting it as a memory leak

			// Platform
			Debug.Assert(io.BackendPlatformUserData == null);

			data.window = window;

			io.BackendPlatformUserData = Internal.UnsafeCastToPtr(data);
			io.BackendPlatformName = "imgui_impl_cacti";
			io.BackendFlags |= .HasMouseCursors;
			io.BackendFlags |= .HasSetMousePos;

			io.SetClipboardTextFn = => SetClipboardText;
			io.GetClipboardTextFn = => GetClipboardText;

#if BF_PLATFORM_WINDOWS
			ImGui.GetMainViewport().PlatformHandleRaw = Glfw.GetWin32Window(window.[Friend]handle);
#endif

			// (By design, on X11 cursors are user configurable and some cursors may be missing. When a cursor doesn't exist,
			// GLFW will emit an error which will often be printed by the app, so we temporarily disable error reporting.
			// Missing cursors will return nullptr and our _UpdateMouseCursor() function will use the Arrow cursor instead.)
			Glfw.ErrorCallback prevErrorCallback =  Glfw.SetErrorCallback(null, false);
			data.cursors[(.) ImGui.MouseCursor.Arrow] = Glfw.CreateStandardCursor(.Arrow);
			data.cursors[(.) ImGui.MouseCursor.TextInput] = Glfw.CreateStandardCursor(.IBeam);
			data.cursors[(.) ImGui.MouseCursor.ResizeNS] = Glfw.CreateStandardCursor(.VResize);
			data.cursors[(.) ImGui.MouseCursor.ResizeEW] = Glfw.CreateStandardCursor(.HResize);
			data.cursors[(.) ImGui.MouseCursor.Hand] = Glfw.CreateStandardCursor(.Hand);
			data.cursors[(.) ImGui.MouseCursor.ResizeAll] = Glfw.CreateStandardCursor(.Arrow);
			data.cursors[(.) ImGui.MouseCursor.ResizeNESW] = Glfw.CreateStandardCursor(.Arrow);
			data.cursors[(.) ImGui.MouseCursor.ResizeNWSE] = Glfw.CreateStandardCursor(.Arrow);
			data.cursors[(.) ImGui.MouseCursor.NotAllowed] = Glfw.CreateStandardCursor(.Arrow);
			Glfw.SetErrorCallback(prevErrorCallback);
			Glfw.GetError(scope .());

			Input.buttonEvent.Add(new (button, action) => {
				UpdateKeyModifiers();

				if (button >= 0 && button < (.) ImGui.MouseButton.COUNT) {
					io.AddMouseButtonEvent((.) button, action == .Press);
				}

				return false;
			}, 1000);

			Input.keyEvent.Add(new (key, scancode, action) => {
				if (action == .Repeat) return false;

				UpdateKeyModifiers();

				ImGui.Key imGuiKey = KeyToImGui(key);
				int32 keycode = KeyToKeycode(key, scancode);

				io.AddKeyEvent(imGuiKey, action == .Press);
				io.SetKeyEventNativeData(imGuiKey, keycode, (.) scancode);

				return false;
			}, 1000);

			Input.charEvent.Add(new (char) => {
				io.AddInputCharacter((.) char);
				return false;
			}, 1000);

			Input.scrollEvent.Add(new (scroll) => {
				io.AddMouseWheelEvent(0, scroll);
				return false;
			}, 1000);

			Input.mousePosEvent.Add(new () => {
				io.AddMousePosEvent(Input.mouse.x, window.Height - Input.mouse.y);
			});

			// Renderer
			Debug.Assert(io.BackendRendererUserData == null);

			io.BackendRendererUserData = Internal.UnsafeCastToPtr(data);
			io.BackendRendererName = "imgui_impl_cacti";
			io.BackendFlags |= .RendererHasVtxOffset;

			CreateObjects();
		}

		public static void Shutdown() {
			delete GetData();
		}

		public static void NewFrame() {
			ImGui.IO* io = ImGui.GetIO();
			Data data = GetData();

			// Platform
			int width = 0, height = 0;
			Glfw.GetWindowSize(data.window.[Friend]handle, ref width, ref height);

			int framebufferWidth = 0, framebufferHeight = 0;
			Glfw.GetFramebufferSize(data.window.[Friend]handle, ref framebufferWidth, ref framebufferHeight);

			io.DisplaySize = .(width, height);

			if (width > 0 && height > 0) {
				io.DisplayFramebufferScale = .((.) framebufferWidth / width, (.) framebufferHeight / height);
			}

			double time = Glfw.GetTime();
			io.DeltaTime = (.) (data.time > 0 ? time - data.time : 1.0 / 60.0);
			data.time = time;

			UpdateMouseData();
			UpdateMouseCursor();
		}

		// Platform

		private static void SetClipboardText(void* userData, char8* text) {
			Data data = GetData();
			Glfw.SetClipboardString(data.window.[Friend]handle, .(text));
		}

		private static char8* GetClipboardText(void* userData) {
			Data data = GetData();
			return Glfw.[Friend]glfwGetClipboardString(data.window.[Friend]handle);
		}

		private static void UpdateMouseData() {
			ImGui.IO* io = ImGui.GetIO();
			Data data = GetData();

			if (Glfw.GetInputMode(data.window.[Friend]handle, .Cursor) == (.) GlfwInput.CursorInputMode.Disabled) {
				io.AddMousePosEvent(float.MinValue, float.MinValue);
				return;
			}

			bool isFocused = Glfw.GetWindowAttrib(data.window.[Friend]handle, .Focused) != 0;

			if (isFocused) {
				// (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when ImGuiConfigFlags_NavEnableSetMousePos is enabled by user)
				if (io.WantSetMousePos) {
					Glfw.SetCursorPos(data.window.[Friend]handle, io.MousePos.x, io.MousePos.y);
				}
			}
		}

		private static void UpdateMouseCursor() {
			ImGui.IO* io = ImGui.GetIO();
			Data data = GetData();

			if ((io.ConfigFlags & .NoMouseCursorChange != 0) || data.window.MouseHidden) {
				return;
			}

			ImGui.MouseCursor imgui_cursor = ImGui.GetMouseCursor();
			if (imgui_cursor == .None || io.MouseDrawCursor) {
				// Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
				data.window.MouseHidden = true;
			}
			else
			{
				// Show OS mouse cursor
				// FIXME-PLATFORM: Unfocused windows seems to fail changing the mouse cursor with GLFW 3.2, but 3.3 works here.
				Glfw.SetCursor(data.window.[Friend]handle, data.cursors[(.) imgui_cursor] != null ? data.cursors[(.) imgui_cursor] : data.cursors[(.) ImGui.MouseCursor.Arrow]);
				data.window.MouseHidden = false;
			}
		}

		private static void UpdateKeyModifiers() {
			ImGui.IO* io = ImGui.GetIO();

			io.AddKeyEvent(.ModCtrl, Input.IsKeyDown(.LeftControl) || Input.IsKeyDown(.RightControl));
			io.AddKeyEvent(.ModShift, Input.IsKeyDown(.LeftShift) || Input.IsKeyDown(.RightShift));
			io.AddKeyEvent(.ModAlt, Input.IsKeyDown(.LeftAlt) || Input.IsKeyDown(.RightAlt));
			io.AddKeyEvent(.ModSuper, Input.IsKeyDown(.LeftSuper) || Input.IsKeyDown(.RightSuper));
		}

		// Renderer

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

		// Other

		private static Data GetData() {
			return ImGui.GetCurrentContext() != null ? (.) Internal.UnsafeCastToObject(ImGui.GetIO().BackendPlatformUserData) : null;
		}

		private static ImGui.Key KeyToImGui(Key key) {
			switch (key) {
				case .Tab:			return .Tab;
				case .Left:			return .LeftArrow;
				case .Right:		return .RightArrow;
				case .Up:			return .UpArrow;
				case .Down:			return .DownArrow;
				case .PageUp:		return .PageUp;
				case .PageDown:		return .PageDown;
				case .Home:			return .Home;
				case .End:			return .End;
				case .Insert:		return .Insert;
				case .Delete:		return .Delete;
				case .Backspace:	return .Backspace;
				case .Space:		return .Space;
				case .Enter:		return .Enter;
				case .Escape:		return .Escape;
				case .Apostrophe:	return .Apostrophe;
				case .Comma:		return .Comma;
				case .Minus:		return .Minus;
				case .Period:		return .Period;
				case .Slash:		return .Slash;
				case .Semicolon:	return .Semicolon;
				case .Equal:		return .Equal;
				case .LeftBracket:	return .LeftBracket;
				case .Backslash:	return .Backslash;
				case .RightBracket:	return .RightBracket;
				case .GraveAccent:	return .GraveAccent;
				case .CapsLock:		return .CapsLock;
				case .ScrollLock:	return .ScrollLock;
				case .NumLock:		return .NumLock;
				case .PrintScreen:	return .PrintScreen;
				case .Pause:		return .Pause;
				case .Kp0:			return .Keypad0;
				case .Kp1:			return .Keypad1;
				case .Kp2:			return .Keypad2;
				case .Kp3:			return .Keypad3;
				case .Kp4:			return .Keypad4;
				case .Kp5:			return .Keypad5;
				case .Kp6:			return .Keypad6;
				case .Kp7:			return .Keypad7;
				case .Kp8:			return .Keypad8;
				case .Kp9:			return .Keypad9;
				case .KpDecimal:	return .KeypadDecimal;
				case .KpDivide:		return .KeypadDivide;
				case .KpMultiply:	return .KeypadMultiply;
				case .KpSubtract:	return .KeypadSubtract;
				case .KpAdd:		return .KeypadAdd;
				case .KpEnter:		return .KeypadEnter;
				case .KpEqual:		return .KeypadEqual;
				case .LeftShift:	return .LeftShift;
				case .LeftControl:	return .LeftCtrl;
				case .LeftAlt:		return .LeftAlt;
				case .LeftSuper:	return .LeftSuper;
				case .RightShift:	return .RightShift;
				case .RightControl:	return .RightCtrl;
				case .RightAlt:		return .RightAlt;
				case .RightSuper:	return .RightSuper;
				case .Menu:			return .Menu;
				case .Num0:			return .Number0;
				case .Num1:			return .Number1;
				case .Num2:			return .Number2;
				case .Num3:			return .Number3;
				case .Num4:			return .Number4;
				case .Num5:			return .Number5;
				case .Num6:			return .Number6;
				case .Num7:			return .Number7;
				case .Num8:			return .Number8;
				case .Num9:			return .Number9;
				case .A:			return .A;
				case .B:			return .B;
				case .C:			return .C;
				case .D:			return .D;
				case .E:			return .E;
				case .F:			return .F;
				case .G:			return .G;
				case .H:			return .H;
				case .I:			return .I;
				case .J:			return .J;
				case .K:			return .K;
				case .L:			return .L;
				case .M:			return .M;
				case .N:			return .N;
				case .O:			return .O;
				case .P:			return .P;
				case .Q:			return .Q;
				case .R:			return .R;
				case .S:			return .S;
				case .T:			return .T;
				case .U:			return .U;
				case .V:			return .V;
				case .W:			return .W;
				case .X:			return .X;
				case .Y:			return .Y;
				case .Z:			return .Z;
				case .F1:			return .F1;
				case .F2:			return .F2;
				case .F3:			return .F3;
				case .F4:			return .F4;
				case .F5:			return .F5;
				case .F6:			return .F6;
				case .F7:			return .F7;
				case .F8:			return .F8;
				case .F9:			return .F9;
				case .F10:			return .F10;
				case .F11:			return .F11;
				case .F12:			return .F12;
				default:			return .None;
			}
		}

		private const String CHAR_NAMES = "`-=[]\\,;\'./";
		private const Key[?] CHAR_KEYS = .(.GraveAccent, .Minus, .Equal, .LeftBracket, .RightBracket, .Backslash, .Comma, .Semicolon, .Apostrophe, .Period, .Slash, 0);

		private static String KEY_NAME = new .() ~ delete _;

		private static int32 KeyToKeycode(Key key, int scancode) {
			if (key >= .Kp0 && key <= .KpEqual) {
				return (.) key;
			}

			var key;

			KEY_NAME.Clear();
			Glfw.GetKeyName(key, scancode, KEY_NAME);

			if (KEY_NAME.Length == 1 && KEY_NAME[0] != 0) {
				if (KEY_NAME[0] >= '0' && KEY_NAME[0] <= '9') {
					key = .Num0 + (KEY_NAME[0] - '0');
				}
				else if (KEY_NAME[0] >= 'A' && KEY_NAME[0] <= 'Z') {
					key = .A + (KEY_NAME[0] - 'A');
				}
				else if (KEY_NAME[0] >= 'a' && KEY_NAME[0] <= 'z') {
					key = .A + (KEY_NAME[0] - 'a');
				}
				else {
					int i = CHAR_NAMES.IndexOf(KEY_NAME[0]);

					if (i != -1) {
						key = CHAR_KEYS[i];
					}
				}
			}

			return (.) key;
		}
	}
}