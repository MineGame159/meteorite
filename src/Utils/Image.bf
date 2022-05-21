using System;

using stb_image;

namespace Meteorite {
	class Image {
		public int width, height, components;

		public uint8* data ~ if (ownsData) stbi.stbi_image_free(_);
		private bool ownsData;

		public this(int width, int height, int components, uint8* data, bool ownsData) {
			this.width = width;
			this.height = height;
			this.components = components;
			this.data = data;
			this.ownsData = ownsData;
		}
	}
}