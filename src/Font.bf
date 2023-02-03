using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite {
	class Font {
		private GpuImage texture ~ delete _;
		private Dictionary<int32, Glyph> glyphs ~ DeleteDictionaryAndValues!(_);

		public int height;

		private DescriptorSet bindGroup ~ delete _;

		public this(GpuImage texture, Dictionary<int32, Glyph> glyphs, int height) {
			this.texture = texture;
			this.glyphs = glyphs;
			this.height = height;
			this.bindGroup = Gfx.DescriptorSets.Create(Gfxa.IMAGE_SET_LAYOUT, .SampledImage(texture, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.NEAREST_SAMPLER));
		}

		public Glyph GetGlyph(char32 c) => glyphs.GetValueOrDefault((.) c);
		
		public void BindTexture(CommandBuffer cmds) => cmds.Bind(bindGroup, 0);

		public static Font Parse(Json json) {
			Image image = Meteorite.INSTANCE.resources.ReadImage(json["file"].AsString[10...]);

			GpuImage texture = Gfx.Images.Create(.RGBA, .Normal, image.size, "Font");
			Gfx.Uploads.UploadImage(texture, image.pixels);

			int height = json.GetInt("height", 8);
			int ascent = json.GetInt("ascent", 0);

			List<List<int32>> chars = scope .();

			for (Json j in json["chars"].AsArray) {
				List<int32> jChars = scope:: .();

				for (let split in j.AsString.Split('\\')) {
					if (split.IsEmpty) continue;
					jChars.Add(int32.Parse(split[1...], .HexNumber));
				}

				chars.Add(jChars);
			}

			int glyphWidth = image.Width / chars[0].Count;
			int glyphHeight = image.Height / chars.Count;
			float scale = (float) height / glyphHeight;
			Dictionary<int32, Glyph> glyphs = new .();

			for (let chars2 in chars) {
				for (let char in chars2) {
					if (char == 0) continue;

					float q = FindCharacterStartX(image, glyphWidth, glyphHeight, @char.Index, @chars2.Index);
					glyphs[char] = new .(image.Width, image.Height, scale, @char.Index * glyphWidth, @chars2.Index * glyphHeight, glyphWidth, glyphHeight, (.) (0.5 + q * scale) + 1, ascent);
				}
			}

			delete image;
			return new .(texture, glyphs, height);
		}

		private static int FindCharacterStartX(Image image, int glyphWidth, int glyphHeight, int charPosX, int charPosY) {
			int i;

			for (i = glyphWidth - 1; i >= 0; i--) {
			    int x = charPosX * glyphWidth + i;

			    for (int j < glyphHeight) {
			        int y = charPosY * glyphHeight + j;
			        if (image.Get(x, y).a == 0) continue;
			        return i + 1;
			    }
			}

			return i + 1;
		}
	}

	class Glyph {
		private int imageWidth, imageHeight;
		private float scale;
		private int x, y;
		private int width, height;
		private int advance, ascent;

		public this(int imageWidth, int imageHeight, float scale, int x, int y, int width, int height, int advance, int ascent) {
			this.imageWidth = imageWidth;
			this.imageHeight = imageHeight;
			this.scale = scale;
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
			this.advance = advance;
			this.ascent = ascent;
		}

		private float Oversample => 1f / scale;
		private float Ascent => 3 + 7 - ascent;

		public float Advance => advance;

		public float MinX => 0;
		public float MinY => Ascent;

		public float MaxX => MinX + width / Oversample;
		public float MaxY => MinY + height / Oversample;

		public float MinU => (x) / (float) imageWidth;
		public float MinV => (y + height) / (float) imageHeight;

		public float MaxU => (x + width) / (float) imageWidth;
		public float MaxV => (y) / (float) imageHeight;
	}
}