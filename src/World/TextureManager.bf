using System;
using System.Collections;

namespace Meteorite {
	class TextureManager {
		private const int SIZE = 1024;

		private TexturePacker packer;
		private List<TempTexture> textures;

		private List<AnimatedTexture> animatedTextures ~ DeleteContainerAndItems!(_);

		private Texture texture ~ delete _;

		private BufferTexture[] bufferData ~ delete _;
		private WBuffer buffer ~ delete _;

		private BindGroup textureBindGroup ~ delete _;
		private BindGroup textureMipmapBindGroup ~ delete _;
		private BindGroup bufferBindGroup ~ delete _;

		public this() {
			packer = new .(SIZE);
			textures = new .();
		}

		public void Tick() {
			// Tick animated textures
			bool upload = false;

			for (AnimatedTexture texture in animatedTextures) {
				if (texture.Tick()) upload = true;
			}

			// Upload buffer
			if (upload) {
				buffer.Write(&bufferData[0], sizeof(BufferTexture) * bufferData.Count);
			}
		}

		public (uint16, TextureRegion) Add(StringView path) {
			if (path.EndsWith("nether_portal.png")) {
				path = path;
			}

			Image image = Meteorite.INSTANCE.resources.ReadImage(path);
			TextureMetadata metadata = .Parse(path);

			if (metadata?.animation == null) {
				let (x, y) = packer.Add(image);
				textures.Add(.(new UV[] (.(x, y)), null));
			}
			else {
				TextureAnimationMetadata animation = metadata.animation;
				metadata.animation = null;

				let (frameWidth, frameHeight) = animation.GetFrameSize(image.width, image.height);

				int framesX = image.width / animation.GetFrameWidth(frameWidth);
				int framesY = image.height / animation.GetFrameHeight(frameHeight);

				if (framesX != 1) Log.Warning("Animated texture {} has multiple frame columns, using only the first one", path);

				if (animation.frames == null) {
					animation.frames = new .(framesY);

					for (int i < framesY) animation.frames.Add(.(i, animation.frameTime));
				}

				UV[] uvs = new .[framesY];
				uint8[] data = new .[frameWidth * frameHeight * 4];

				for (let frame in animation.frames) {
					int y = frame.index * frameHeight;

					for (int i < frameHeight) {
						Internal.MemCpy(&data[(i * frameWidth) * 4], &image.data[(y + i) * image.width * 4], frameWidth * 4);
					}

					let (x1, y1) = packer.Add(scope .(frameWidth, frameHeight, 4, &data[0], false));
					uvs[frame.index] = .(x1, y1);
				}

				delete data;
				textures.Add(.(uvs, animation));
			}

			delete metadata;
			delete image;
			
			return ((.) textures.Count - 1, .(0, 0, 255, 255));
		}

		public void Finish() {
			animatedTextures = new .();

			// Texture
			texture = packer.CreateTexture("Block atlas");
			delete packer;

			// Buffer
			bufferData = new .[textures.Count];

			for (int i < textures.Count) {
				let tex = textures[i];
				BufferTexture* texture = &bufferData[i];

				float x = tex.uvs[0].x;
				float y = tex.uvs[0].y;

				texture.uv1 = .(x / SIZE, y / SIZE);
				texture.size = 16f / SIZE;

				if (tex.uvs.Count > 1) {
					Frame[] frames = new .[tex.animation.frames.Count];

					for (int j < frames.Count) {
						AnimationFrame frame = tex.animation.frames[j];
						frames[j] = .(tex.uvs[frame.index], frame.GetTime(tex.animation.frameTime));
					}

					animatedTextures.Add(new .(texture, frames, tex.animation.interpolate));
				}

				tex.Dispose();
			}

			buffer = Gfx.CreateBuffer(.Storage | .CopyDst, sizeof(BufferTexture) * bufferData.Count, &bufferData[0], "Textures buffer");
			
			delete textures;

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

		struct TempTexture : this(UV[] uvs, TextureAnimationMetadata animation) {
			public void Dispose() {
				delete uvs;
				delete animation;
			}
		}

		class AnimatedTexture {
			private BufferTexture* buffer;

			private Frame[] frames ~ delete _;
			private bool interpolate;

			private int frame;
			private int timer;

			public this(BufferTexture* buffer, Frame[] frames, bool interpolate) {
				this.buffer = buffer;
				this.frames = frames;
				this.interpolate = interpolate;
			}

			public bool Tick() {
				timer++;

				if (timer >= frames[frame].time) {
					frame++;
					if (frame >= frames.Count) frame = 0;

					buffer.uv1 = .((float) frames[frame].uv.x / SIZE, (float) frames[frame].uv.y / SIZE);
					buffer.blend = 0;

					timer = 0;
					return true;
				}
				else if (interpolate) {
					int nextFrame = frame + 1;
					if (nextFrame >= frames.Count) nextFrame = 0;

					buffer.uv2 = .((float) frames[nextFrame].uv.x / SIZE, (float) frames[nextFrame].uv.y / SIZE);
					buffer.blend = (float) timer / frames[frame].time;

					return true;
				}

				return false;
			}
		}

		struct Frame : this(UV uv, int time) {}

		struct BufferTexture {
			public Vec2 uv1, uv2;
			public float size, blend;
		}

		struct UV : this(int x, int y) {}
	}
}