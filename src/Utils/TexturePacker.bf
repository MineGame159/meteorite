using System;
using System.IO;
using System.Collections;
using StbImageBeef;

namespace Meteorite {
	class TexturePacker {
		private int size;
		private uint8*[4] datas ~ for (uint8* data in _) delete data;
		private uint8* data ~ delete _;

		private int x, y;
		private int maxRowHeight;

		public this(int size) {
			this.size = size;

			int s = size;
			for (int i < 4) {
				datas[i] = new uint8[s * s * 4]*;
				s >>= 1;
			}
		}

		public (int, int) Add(StringView path) {
			// Read image
			FileStream fs = scope .();
			if (fs.Open(path, .Read) case .Err) {
				Log.Error("Failed to open file '{}'", path);
				return (0, 0);
			}

			ImageResult image = ImageResult.FromStream(fs, .RedGreenBlueAlpha);
			List<Mipmap> mipmaps = scope .(4);
			MipmapGenerator.Generate(image.Data, image.Width, image.Height, 4, mipmaps);

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
			
			x += image.Width;
			if (image.Height > maxRowHeight) maxRowHeight = image.Height;

			if (x >= size) {
				x = 0;
				y += maxRowHeight;
				maxRowHeight = 0;
			}

			delete image;
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