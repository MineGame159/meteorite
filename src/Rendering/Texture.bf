using System;

using static Meteorite.GL;

namespace Meteorite {
	enum TextureFiltera {
		case Nearest;
		case NearestMipmapLinear;

		public int ToOpenGL() {
			switch (this) {
			case .Nearest: return GL_NEAREST;
			case .NearestMipmapLinear: return GL_NEAREST_MIPMAP_LINEAR;
			}
		}
	}

	class Texturea {
		public int width, height;

		private uint32 id ~ glDeleteTextures(1, &_);

		public this(StringView name, int width, int height, int levels = 1, TextureFiltera min = .Nearest, TextureFiltera mag = .Nearest) {
			this.width = width;
			this.height = height;

			glCreateTextures(GL_TEXTURE_2D, 1, &id);
			glObjectLabel(GL_TEXTURE, id, name.Length, name.ToScopeCStr!());

			glTextureParameteri(id, GL_TEXTURE_MIN_FILTER, min.ToOpenGL());
			glTextureParameteri(id, GL_TEXTURE_MAG_FILTER, mag.ToOpenGL());
			glTextureParameteri(id, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTextureParameteri(id, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

			glTextureStorage2D(id, levels, GL_RGBA8, width, height);
		}

		public void SetMinFilter(TextureFiltera min) => glTextureParameteri(id, GL_TEXTURE_MIN_FILTER, min.ToOpenGL());
		public void SetMagFilter(TextureFiltera mag) => glTextureParameteri(id, GL_TEXTURE_MAG_FILTER, mag.ToOpenGL());

		public void Upload(uint8* data, int level, int width, int height) {
			glTextureSubImage2D(id, level, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
		}
		public void Upload(uint8* data) => Upload(data, 0, width, height);

		public int Bind(int unit = 0) {
			glBindTextureUnit((.) unit, id);
			return unit;
		}
	}
}