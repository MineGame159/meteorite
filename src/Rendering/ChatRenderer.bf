using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class ChatRenderer {
		private const Color BACKGROUND = .(0, 0, 0, 125);

		private Meteorite me = .INSTANCE;

		private List<Text> messages = new .() ~ DeleteContainerAndItems!(_);
		private List<Message> visibleMessages = new .() ~ DeleteContainerAndItems!(_);

		private bool typing, showCursor, wasMouseHidden, firstChar;
		private int cursor;

		private String toSend = new .() ~ delete _;
		private float cursorTimer, textEndX;
		private int renderFrom;

		private List<String> sentMessages = new .(16) ~ DeleteContainerAndItems!(_);
		private int previousMessageI;

		public this() {
			Input.keyEvent.Add(new => OnKey);
			Input.charEvent.Add(new => OnChar);
			Input.scrollEvent.Add(new => OnScroll);
		}

		public void AddMessage(Text message) {
			messages.AddFront(message.Copy());
			if (messages.Count > 100) delete messages.PopBack();

			visibleMessages.AddFront(new .(message));
			
			Log.Info("Chat: {}", message);
		}

		public void Render(CommandBuffer cmds, float delta) {
			me.textRenderer.Begin();
			MeshBuilder mb = scope .(false);

			RenderMessages(cmds, mb, delta);
			if (typing) RenderTyping(cmds, mb, delta, true);

			cmds.Bind(Gfxa.PIXEL_SET, 0);
			cmds.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));

			me.textRenderer.BindTexture(cmds);
			me.textRenderer.End(cmds);

			if (typing) {
				mb = scope .(false);
				RenderTyping(cmds, mb, delta, false);

				cmds.Bind(Gfxa.PIXEL_SET, 0);
				cmds.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));
			}
		}

		private void RenderMessages(CommandBuffer cmds, MeshBuilder mb, float delta) {
			// Remove visible messages if they are displayed for too long
			for (let message in visibleMessages) {
				message.timer += delta;

				if (message.timer >= 10) {
					@message.Remove();
					delete message;
					continue;
				}
			}

			// Render messages while having the chat open
			float y = 2 + me.textRenderer.Height + 8;

			if (typing) {
				for (int i = renderFrom; i < Math.Min(messages.Count, renderFrom + 16); i++) {
					float x = 4;
					messages[i].Visit(scope [&](text, color) => x = me.textRenderer.Render(x, y, text, color));

					y += me.textRenderer.Height + 2;
				}

				return;
			}

			// Render visible messages while the chat is closed
			for (let message in visibleMessages) {
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

		private void RenderTyping(CommandBuffer cmds, MeshBuilder mb, float delta, bool first) {
			if (first) {
				cursorTimer += delta * 2;
				if (cursorTimer >= 1) {
					showCursor = !showCursor;
					cursorTimer = 0;
				}
	
				Quad(mb, 2, 2, me.window.Width / 2 - 4, me.textRenderer.Height * 1.75f, BACKGROUND);
				textEndX = me.textRenderer.Render(4, 2, toSend, .WHITE);
				
				if (showCursor && cursor == toSend.Length) {
					me.textRenderer.Render(textEndX, 2, "_", .WHITE);
				}
			}
			else {
				if (showCursor && cursor != toSend.Length) {
					float x = 3 + me.textRenderer.GetWidth(toSend.Substring(0, cursor));
					Quad(mb, x, 4, 1, me.textRenderer.Height + 2, .WHITE);
				}
			}
		}

		private void Quad(MeshBuilder mb, float x, float y, float width, float height, Color color) {
			mb.Quad(
				mb.Vertex<Pos2DUVColorVertex>(.(.(x, y), .(0, 0), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x, y + height), .(0, 1), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + width, y + height), .(1, 1), color)),
				mb.Vertex<Pos2DUVColorVertex>(.(.(x + width, y), .(1, 0), color))
			);
		}

		private bool OnKey(Key key, int scancode, InputAction action) {
			if (me.Screen != null || action == .Release) return false;

			if (typing) {
				if (key == .Escape || key == .Enter || key == .KpEnter) {
					typing = false;
					me.window.MouseHidden = wasMouseHidden;

					Input.capturingCharacters = false;

					if ((key == .Enter || key == .KpEnter) && !toSend.IsEmpty) {
						me.connection.Send(scope ChatC2SPacket(toSend));

						sentMessages.AddFront(new .(toSend));
						if (sentMessages.Count > 16) delete sentMessages.PopBack();
					}

					return true;
				}
				if (key == .Up) {
					if (sentMessages.Count > previousMessageI + 1) {
						toSend.Set(sentMessages[++previousMessageI]);
						cursor = toSend.Length;
					}

					return true;
				}
				if (key == .Down) {
					previousMessageI--;
					if (previousMessageI < -1) previousMessageI = -1;

					if (sentMessages.Count > previousMessageI) {
						toSend.Set(previousMessageI < 0 ? "" : sentMessages[previousMessageI]);
						cursor = toSend.Length;
					}

					return true;
				}
				if (key == .Backspace) {
					if (!toSend.IsEmpty && cursor > 0) {
						if (cursor == toSend.Length) toSend.RemoveFromEnd(1);
						else toSend.Remove(cursor - 1);

						cursor--;
					}

					previousMessageI = -1;
					return true;
				}
				if (key == .Delete) {
					if (!toSend.IsEmpty && cursor < toSend.Length) {
						toSend.Remove(cursor);
					}

					previousMessageI = -1;
					return true;
				}
				if (key == .Left) {
					cursor--;
					if (cursor < 0) cursor = 0;

					return true;
				}
				if (key == .Right) {
					cursor++;
					if (cursor > toSend.Length) cursor = toSend.Length;

					return true;
				}
			}
			else {
				if (key == .T || key == .Slash || key == .KpDivide) {
					typing = true;
					showCursor = false;
					firstChar = true;
					cursor = 0;
					toSend.Clear();
					cursorTimer = 0;
					renderFrom = 0;
					previousMessageI = -1;

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
			if (me.Screen != null) return false;

			if (typing) {
				if (firstChar) {
					firstChar = false;
					return false;
				}

				toSend.Insert(cursor, char);
				cursor++;

				previousMessageI = -1;
				return true;
			}

			return false;
		}

		private bool OnScroll(float scroll) {
			if (me.Screen != null) return false;

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