using System;

using stb_image;

namespace Meteorite {
	class Image {
		public int width, height, components;
		public uint8* data ~ stbi.stbi_image_free(_);

		public this(int width, int height, int components, uint8* data) {
			this.width = width;
			this.height = height;
			this.components = components;
			this.data = data;
		}
	}
}