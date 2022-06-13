using System;
using System.Collections;

namespace Meteorite {
	class ChatRenderer {
		private const Color BACKGROUND = .(0, 0, 0, 125);

		private Meteorite me = .INSTANCE;

		private List<Text> messages = new .() ~ DeleteContainerAndItems!(_);
		private List<Message> visibleMessages = new .() ~ DeleteContainerAndItems!(_);

		private bool typing, showCursor, wasMouseHidden, firstChar;
		private String toSend = new .() ~ delete _;
		private float cursorTimer;
		private int renderFrom;

		private List<String> sentMessages = new .(16) ~ DeleteContainerAndItems!(_);
		private int idk;

		public this() {
			Input.keyEvent.Add(new => OnKey);
			Input.charEvent.Add(new => OnChar);
			Input.scrollEvent.Add(new => OnScroll);
		}

		public void AddMessage(Text message) {
			messages.AddFront(message.Copy());
			if (messages.Count > 100) delete messages.PopBack();

			visibleMessages.AddFront(new .(message));
			
			Log.Chat("{}", message);
		}

		public void Render(RenderPass pass, float delta) {
			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass, Buffers.QUAD_INDICES);
			me.textRenderer.Begin(pass);

			RenderMessages(pass, mb, delta);
			if (typing) RenderTyping(pass, mb, delta);

			Gfxa.PIXEL_BIND_GRUP.Bind(pass);
			mb.Finish();

			me.textRenderer.BindTexture(pass);
			me.textRenderer.End();
		}

		private void RenderMessages(RenderPass pass, MeshBuilder mb, float delta) {
			float y = 2 + me.textRenderer.Height + 8;

			if (typing) {
				for (int i = renderFrom; i < Math.Min(messages.Count, renderFrom + 16); i++) {
					float x = 4;
					messages[i].Visit(scope [&](text, color) => x = me.textRenderer.Render(x, y, text, color));

					y += me.textRenderer.Height + 2;
				}

				return;
			}

			for (let message in visibleMessages) {
				message.timer += delta;
				if (message.timer >= 10) {
					@message.Remove();
					delete message;
					continue;
				}

				if (@message.Index < 10) {
					float x = 4;
					message.text.Visit(scope [&](text, color) => {
						Color c = color;

						if (message.timer >= 9) {
							float f = 10 - message.timer;
							c.a = (.) (c.A * f * 255);
						}

						x = me.textRenderer.Render(x, y, text, c);
					});
					
					y += me.textRenderer.Height + 2;
				}
			}
		}

		private void RenderTyping(RenderPass pass, MeshBuilder mb, float delta) {
			cursorTimer += delta * 2;
			if (cursorTimer >= 1) {
				showCursor = !showCursor;
				cursorTimer = 0;
			}

			float x = me.textRenderer.Render(4, 2, toSend, .WHITE);
			if (showCursor) me.textRenderer.Render(x, 2, "_", .WHITE);

			Quad(mb, 2, 2, me.window.width / 2 - 4, me.textRenderer.Height * 1.75f, BACKGROUND);
		}

		private void Quad(MeshBuilder mb, float x, float y, float width, float height, Color color) {
			mb.Quad(
				mb.Vec2(.(x, y)).Vec2(.(0, 0)).Color(color).Next(),
				mb.Vec2(.(x, y + height)).Vec2(.(0, 1)).Color(color).Next(),
				mb.Vec2(.(x + width, y + height)).Vec2(.(1, 1)).Color(color).Next(),
				mb.Vec2(.(x + width, y)).Vec2(.(1, 0)).Color(color).Next()
			);
		}

		private bool OnKey(Key key, InputAction action) {
			if (action == .Release) return false;

			if (typing) {
				if (key == .Escape || key == .Enter || key == .KpEnter) {
					typing = false;
					me.window.MouseHidden = wasMouseHidden;

					Input.capturingCharacters = false;

					if ((key == .Enter || key == .KpEnter) && !toSend.IsEmpty) {
						me.connection.Send(scope MessageC2SPacket(toSend));

						sentMessages.AddFront(new .(toSend));
						if (sentMessages.Count > 16) delete sentMessages.PopBack();
					}

					return true;
				}
				if (key == .Up) {
					if (sentMessages.Count > idk + 1) toSend.Set(sentMessages[++idk]);
					return true;
				}
				if (key == .Down) {
					idk--;
					if (idk < -1) idk = -1;
					if (sentMessages.Count > idk) toSend.Set(idk < 0 ? "" : sentMessages[idk]);
					return true;
				}
				if (key == .Backspace) {
					if (!toSend.IsEmpty) toSend.RemoveFromEnd(1);
					idk = -1;
					return true;
				}
			}
			else {
				if (key == .T || key == .Slash || key == .KpDivide) {
					typing = true;
					showCursor = false;
					firstChar = true;
					toSend.Clear();
					cursorTimer = 0;
					renderFrom = 0;
					idk = -1;

					wasMouseHidden = me.window.MouseHidden;
					me.window.MouseHidden = false;

					Input.capturingCharacters = true;

					if (key == .Slash || key == .KpDivide) toSend.Append('/');
					return true;
				}
			}

			return false;
		}

		private bool OnChar(char32 char) {
			if (typing) {
				if (firstChar) {
					firstChar = false;
					return false;
				}

				toSend.Append(char);
				idk = -1;
				return true;
			}

			return false;
		}

		private bool OnScroll(float scroll) {
			if (typing) {
				renderFrom += (.) scroll;
				renderFrom = Math.Clamp(renderFrom, 0, messages.Count - 16 - 1);
				return true;
			}

			return false;
		}

		class Message {
			public Text text ~ delete _;
			public float timer;

			public this(Text message) {
				text = message.Copy();
			}
		}
	}
}