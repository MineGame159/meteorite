using System;
using System.Collections;

namespace Meteorite {
	class TexturePacker {
		private int size;
		private uint8*[4] datas ~ for (uint8* data in _) Internal.StdFree(data);
		
		private int x, y;
		private int maxRowHeight;

		public this(int size) {
			this.size = size;

			int s = size;
			for (int i < 4) {
				datas[i] = (.) Internal.StdMalloc(s * s * 4);
				s >>= 1;
			}
		}

		public (int, int) Add(Image image) {
			// Generate mipmap
			List<Mipmap> mipmaps = scope .(4);
			MipmapGenerator.Generate(image.data, image.width, image.height, 4, mipmaps);

			// Copy texture to atlas
			int divide = 1;
			for (int i < mipmaps.Count) {
				Mipmap mipmap = mipmaps[i];

				for (int j < mipmap.h) {
					Internal.MemCpy(&datas[i][((y / divide + j) * size + x) * 4 / divide], &mipmap.pixels[j * mipmap.w * 4], mipmap.w * 4);
				}

				divide += divide;
			}

			for (Mipmap mipmap in mipmaps) mipmap.Dispose();

			// Save and update position
			int _x = x;
			int _y = y;
			
			x += image.width;
			if (image.height > maxRowHeight) maxRowHeight = image.height;

			if (x >= size) {
				x = 0;
				y += maxRowHeight;
				maxRowHeight = 0;
			}
			
			return (_x, _y);
		}

		public Texture CreateTexture(StringView name) {
			Texture texture = Gfx.CreateTexture(.TextureBinding | .CopyDst, size, size, 4, null);

			int s = size;
			for (int i < 4) {
				texture.Write(s, s, i, datas[i]);
				s >>= 1;
			}

			return texture;
		}
	}
}