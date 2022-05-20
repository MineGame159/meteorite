using System;
using System.Collections;

namespace Meteorite {
	class TextureManager {
		private const int SIZE = 512;

		private TexturePacker packer;
		private List<(int, int)> textures;

		private Texture texture ~ delete _;
		private WBuffer buffer ~ delete _;

		private BindGroup textureBindGroup ~ delete _;
		private BindGroup textureMipmapBindGroup ~ delete _;
		private BindGroup bufferBindGroup ~ delete _;

		public this() {
			packer = new .(SIZE);
			textures = new .();
		}

		public (uint16, TextureRegion) Add(StringView path) {
			textures.Add(packer.Add(path));

			return ((.) textures.Count - 1, .(0, 0, 255, 255));
		}

		public void Finish() {
			// Texture
			texture = packer.CreateTexture("Block atlas");
			delete packer;

			// Buffer
			GTexture[] data = new .[textures.Count];

			for (int i < textures.Count) {
				let (x, y) = textures[i];
				ref GTexture texture = ref data[i];

				texture.uv1 = .((float) x / SIZE, (float) y / SIZE);
				texture.size = 16f / SIZE;
			}

			buffer = Gfx.CreateBuffer(.Storage, sizeof(GTexture) * data.Count, &data[0]);

			delete textures;
			delete data;

			// Bind groups
			textureBindGroup = Gfxa.TEXTURE_SAMPLER_LAYOUT.Create(texture, Gfxa.NEAREST_SAMPLER);
			textureMipmapBindGroup = Gfxa.TEXTURE_SAMPLER_LAYOUT.Create(texture, Gfxa.NEAREST_MIPMAP_SAMPLER);
			bufferBindGroup = Gfxa.BUFFER_SAMPLER_LAYOUT.Create(buffer);
		}

		public void Bind(bool mipmaps) {
			if (mipmaps) textureMipmapBindGroup.Bind();
			else textureBindGroup.Bind();

			bufferBindGroup.Bind(1);
		}

		struct GTexture {
			public Vec2 uv1, uv2;
			public float size, blend;
		}
	}
}