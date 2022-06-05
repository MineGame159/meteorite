using System;
using System.Collections;

namespace Meteorite {
	class TextureManager {
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
			packer = new .(8192);
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

		public uint16 Add(StringView path) {
			Image image = Meteorite.INSTANCE.resources.ReadImageInfo(path);
			TextureMetadata metadata = .Parse(path);

			if (metadata?.animation == null) {
				UV[] uvs = new .[1];
				packer.Add(image, &uvs[0].x, &uvs[0].y);
				textures.Add(.(new .(path), uvs, image.width, null));
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

				for (let frame in animation.frames) {
					uvs[frame.index].index = frame.index;
					packer.Add(scope .(frameWidth, frameHeight, 4, null, false), &uvs[frame.index].x, &uvs[frame.index].y);
				}

				textures.Add(.(new .(path), uvs, frameWidth, animation));
			}

			delete metadata;
			delete image;
			
			return (.) textures.Count - 1;
		}

		public void Finish() {
			animatedTextures = new .();

			// Packer
			int size = packer.Finish();
			if (size == -1) Log.Error("Exceeded maximum texture atlas size 8192");
			delete packer;

			// Atlas
			TextureAtlas atlas = scope .(size);
			for (let texture in textures) {
				Image image = Meteorite.INSTANCE.resources.ReadImage(texture.path);
				TextureMetadata metadata = .Parse(texture.path);

				if (texture.uvs.Count == 1) {
					atlas.Put(image, texture.uvs[0].x, texture.uvs[0].y);
				}
				else {
					uint8[] data = new .[texture.size * texture.size * 4];

					for (let uv in texture.uvs) {
						int y = uv.index * texture.size;
						for (int i < texture.size) {
							Internal.MemCpy(&data[(i * texture.size) * 4], &image.data[(y + i) * image.width * 4], texture.size * 4);
						}
						atlas.Put(scope .(texture.size, texture.size, 4, &data[0], false), uv.x, uv.y);
					}

					delete data;
				}

				delete metadata;
				delete image;
			}
			texture = atlas.Finish();

			// Buffer
			bufferData = new .[textures.Count];

			for (int i < textures.Count) {
				let tex = textures[i];
				BufferTexture* texture = &bufferData[i];

				float x = tex.uvs[0].x;
				float y = tex.uvs[0].y;

				texture.uv1 = .(x / size, y / size);
				texture.size = (float) tex.size / size;

				if (tex.uvs.Count > 1) {
					Frame[] frames = new .[tex.animation.frames.Count];

					for (int j < frames.Count) {
						AnimationFrame frame = tex.animation.frames[j];
						frames[j] = .(tex.uvs[frame.index], frame.GetTime(tex.animation.frameTime));
					}

					animatedTextures.Add(new .(texture, frames, tex.animation.interpolate, size));
				}

				tex.Dispose();
			}

			buffer = Gfx.CreateBuffer(.Storage | .CopyDst, sizeof(BufferTexture) * bufferData.Count, &bufferData[0], "Textures buffer");
			
			DeleteAndNullify!(textures);

			// Bind groups
			textureBindGroup = Gfxa.TEXTURE_SAMPLER_LAYOUT.Create(texture, Gfxa.NEAREST_SAMPLER);
			textureMipmapBindGroup = Gfxa.TEXTURE_SAMPLER_LAYOUT.Create(texture, Gfxa.NEAREST_MIPMAP_SAMPLER);
			bufferBindGroup = Gfxa.BUFFER_SAMPLER_LAYOUT.Create(buffer);
		}

		public void Bind(RenderPass pass, bool mipmaps) {
			if (mipmaps) textureMipmapBindGroup.Bind(pass);
			else textureBindGroup.Bind(pass);

			bufferBindGroup.Bind(pass, 1);
		}

		struct TempTexture : this(String path, UV[] uvs, int size, TextureAnimationMetadata animation) {
			public void Dispose() {
				delete path;
				delete uvs;
				delete animation;
			}
		}

		class AnimatedTexture {
			private BufferTexture* buffer;

			private Frame[] frames ~ delete _;
			private bool interpolate;
			private int atlasSize;

			private int frame;
			private int timer;

			public this(BufferTexture* buffer, Frame[] frames, bool interpolate, int atlasSize) {
				this.buffer = buffer;
				this.frames = frames;
				this.interpolate = interpolate;
				this.atlasSize = atlasSize;
			}

			public bool Tick() {
				timer++;

				if (timer >= frames[frame].time) {
					frame++;
					if (frame >= frames.Count) frame = 0;

					buffer.uv1 = .((float) frames[frame].uv.x / atlasSize, (float) frames[frame].uv.y / atlasSize);
					buffer.blend = 0;

					timer = 0;
					return true;
				}
				else if (interpolate) {
					int nextFrame = frame + 1;
					if (nextFrame >= frames.Count) nextFrame = 0;

					buffer.uv2 = .((float) frames[nextFrame].uv.x / atlasSize, (float) frames[nextFrame].uv.y / atlasSize);
					buffer.blend = (float) timer / frames[frame].time;

					return true;
				}

				return false;
			}
		}

		struct Frame : this(UV uv, int time) {}

		struct BufferTexture {
			public Vec2f uv1, uv2;
			public float size, blend;
		}

		struct UV : this(int index, int x, int y) {}
	}
}