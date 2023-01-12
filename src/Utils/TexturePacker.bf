using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class TexturePacker {
		struct Entry : this(int width, int height, int* x, int* y) {}

		private int maxSize;
		private List<Entry> entries = new .() ~ delete _;

		private int x, y;
		private int maxRowHeight;

		public this(int maxSize) {
			this.maxSize = maxSize;
		}

		public void Add(ImageInfo image, int* x, int* y) {
			entries.Add(.(image.Width, image.Height, x, y));
		}

		public int Finish() {
			int size = 512;

			while (true) {
				if (Calculate(size)) return size;
				
				size *= 2;
				if (size >= maxSize) return -1;
			}
		}

		private bool Calculate(int maxSize) {
			x = y = 0;
			maxRowHeight = 0;

			for (let entry in entries) {
				*entry.x = x;
				*entry.y = y;

				x += entry.width;
				if (entry.height > maxRowHeight) maxRowHeight = entry.height;

				if (x >= maxSize) {
					x = 0;
					y += maxRowHeight;
					maxRowHeight = 0;
				}

				if (y + maxRowHeight > maxSize) return false;
			}

			return true;
		}
	}

	class TextureAtlas {
		private int size;
		private uint8*[4] datas ~ for (uint8* data in _) Internal.StdFree(data);

		public this(int size) {
			this.size = size;

			int s = size;
			for (int i < 4) {
				datas[i] = (.) Internal.StdMalloc(s * s * 4);
				s >>= 1;
			}
		}

		public void Put(Image image, int x, int y) {
			// Generate mipmap
			List<Mipmap> mipmaps = scope .(4);
			MipmapGenerator.Generate(image.pixels, image.Width, image.Height, 4, mipmaps);

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
		}

		public GpuImage Finish() {
			GpuImage image = Gfx.Images.Create(.RGBA, .Normal, .(size, size), "Block Atlas", 4);

			for (int i < 4) {
				Gfx.Uploads.UploadImage(image, datas[i], i);
			}

			return image;
		}
	}
}