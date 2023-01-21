using System;

using Cacti;

namespace Meteorite {
	class TextRenderer {
		private Font font ~ delete _;

		private MeshBuilder mb;

		public int Height => font.height;

		public this() {
			Json json = Meteorite.INSTANCE.resources.ReadJson("font/default.json");
			for (let j in json["providers"].AsArray) {
				if (j.Contains("file") && j["file"].AsString.EndsWith("ascii.png")) {
					font = Font.Parse(j);
					break;
				}
			}
			json.Dispose();

			if (font == null) Log.Error("Failed to load default/ascii font");
		}

		public void Begin() {
			if (mb == null) mb = new .(false);
		}

		public void End(CommandBuffer cmds) {
			cmds.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));
			DeleteAndNullify!(mb);
		}

		public float Render(float x, float y, StringView text, Color color, bool shadow = true) {
			float x2 = 0;

			if (shadow) {
				Color c = color;
				c.r = (.) (c.R * 0.25 * 255);
				c.g = (.) (c.G * 0.25 * 255);
				c.b = (.) (c.B * 0.25 * 255);

				x2 = RenderInternal(mb, x + 1, y - 1, text, c);
			}

			return Math.Max(x2, RenderInternal(mb, x, y, text, color));
		}

		public float GetWidth(StringView text) {
			float width = 0;

			for (let char in text.DecodedChars) {
				Glyph glyph = font.GetGlyph(char);

				if (glyph != null) {
					width += glyph.Advance * (char == ' ' ? 4 : 1);
				}
				else {
					width += font.GetGlyph(' ').Advance * 4;
				}
			}

			return width;
		}

		private float RenderInternal(MeshBuilder mb, float x, float y, StringView text, Color color) {
			var x;

			for (let char in text.DecodedChars) {
				Glyph glyph = font.GetGlyph(char);

				if (glyph == null) {
					x += font.GetGlyph(' ').Advance * 4;
					continue;
				}

				mb.Quad(
					mb.Vertex<Pos2DUVColorVertex>(.(.(x + glyph.MinX, y + glyph.MinY), .(glyph.MinU, glyph.MinV), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(x + glyph.MinX, y + glyph.MaxY), .(glyph.MinU, glyph.MaxV), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(x + glyph.MaxX, y + glyph.MaxY), .(glyph.MaxU, glyph.MaxV), color)),
					mb.Vertex<Pos2DUVColorVertex>(.(.(x + glyph.MaxX, y + glyph.MinY), .(glyph.MaxU, glyph.MinV), color))
				);

				x += char == ' ' ? glyph.Advance * 4 : glyph.Advance;
			}

			return x;
		}

		public void BindTexture(CommandBuffer cmds) => font.BindTexture(cmds);
	}
}