using System;

namespace Meteorite {
	class TextRenderer {
		private Font font ~ delete _;

		private MeshBuilder mb;

		public int Height => font.height;

		public this() {
			Json json = Meteorite.INSTANCE.resources.ReadJson("font/default.json");
			for (let j in json["providers"].AsArray) {
				if (j["file"].AsString.EndsWith("ascii.png")) {
					font = Font.Parse(j);
					break;
				}
			}
			json.Dispose();

			if (font == null) Log.Error("Failed to load default/ascii font");
		}

		public void Begin(RenderPass pass) {
			if (mb == null) mb = Meteorite.INSTANCE.frameBuffers.AllocateImmediate(pass, Buffers.QUAD_INDICES);
		}

		public void End() {
			mb.Finish();
			mb = null;
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

		private float RenderInternal(MeshBuilder mb, float x, float y, StringView text, Color color) {
			var x;

			for (let char in text.DecodedChars) {
				Glyph glyph = font.GetGlyph(char);

				if (glyph == null) {
					x += font.GetGlyph(' ').Advance * 4;
					continue;
				}

				mb.Quad(
					mb.Vec2(.(x + glyph.MinX, y + glyph.MinY)).Vec2(.(glyph.MinU, glyph.MinV)).Color(color).Next(),
					mb.Vec2(.(x + glyph.MinX, y + glyph.MaxY)).Vec2(.(glyph.MinU, glyph.MaxV)).Color(color).Next(),
					mb.Vec2(.(x + glyph.MaxX, y + glyph.MaxY)).Vec2(.(glyph.MaxU, glyph.MaxV)).Color(color).Next(),
					mb.Vec2(.(x + glyph.MaxX, y + glyph.MinY)).Vec2(.(glyph.MaxU, glyph.MinV)).Color(color).Next()
				);

				x += char == ' ' ? glyph.Advance * 4 : glyph.Advance;
			}

			return x;
		}

		public void BindTexture(RenderPass pass) => font.BindTexture(pass);
	}
}