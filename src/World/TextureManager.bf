using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

class TextureManager {
	private TexturePacker packer;
	private List<TempTexture> textures;
	private uint16? missingTexture;

	private List<AnimatedTexture> animatedTextures ~ DeleteContainerAndItems!(_);

	private GpuImage texture ~ ReleaseAndNullify!(_);

	private BufferTexture[] bufferData ~ delete _;
	private GpuBuffer buffer ~ ReleaseAndNullify!(_);

	private Dictionary<String, GpuImage> bindableTextures = new .();

	public this() {
		packer = new .(8192);
		textures = new .();
	}

	public ~this() {
		for (let (path, image) in bindableTextures) {
			delete path;
			image.Release();
		}

		delete bindableTextures;
	}

	public Descriptor ImageDescriptor => .SampledImage(texture, Gfxa.NEAREST_MIPMAP_SAMPLER);
	public Descriptor BufferDescriptor => .Uniform(buffer);

	public Descriptor GetDescriptor(StringView path) {
		GpuImage image;

		if (!bindableTextures.TryGetValueAlt(path, out image)) {
			image = Gfxa.CreateImage(path);
			bindableTextures[new .(path)] = image;
		}

		return .SampledImage(image, Gfxa.NEAREST_SAMPLER);
	}
	
	[Tracy.Profile]
	public void Tick() {
		// Tick animated textures
		bool upload = false;

		for (AnimatedTexture texture in animatedTextures) {
			if (texture.Tick()) upload = true;
		}

		// Upload buffer
		if (upload) {
			buffer.Upload(&bufferData[0], (.) (sizeof(BufferTexture) * bufferData.Count));
		}
	}

	public uint16 Add(StringView path) {
		Result<ImageInfo> imageResult = Meteorite.INSTANCE.resources.ReadImageInfo(path);

		if (imageResult == .Err) {
			Log.Debug("Texture '{}' is missing, using a fallback", path);
			return AddMissingTexture();
		}

		ImageInfo image = imageResult;
		TextureMetadata metadata = .Parse(path);

		if (metadata?.animation == null) {
			UV[] uvs = new .[1];
			packer.Add(image, &uvs[0].x, &uvs[0].y);
			textures.Add(.(new .(path), uvs, image.Width, null));
		}
		else {
			// TODO: This whole animation loading is fucked
			TextureAnimationMetadata animation = metadata.animation;
			metadata.animation = null;

			let (frameWidth, frameHeight) = animation.GetFrameSize(image.Width, image.Height);

			int framesX = image.Width / animation.GetFrameWidth(frameWidth);
			int framesY = image.Height / animation.GetFrameHeight(frameHeight);

			if (framesX != 1) Log.Warning("Animated texture {} has multiple frame columns, using only the first one", path);

			if (animation.frames == null) {
				animation.frames = new .(framesY);

				for (int i < framesY) animation.frames.Add(.(i, animation.frameTime));
			}

			UV[] uvs = new .[framesY];

			// framesY can be smaller than the number of frames specified inside the json, for example when a resource pack overrides the texture but not the animation json file
			// don't know what the correct outcome should be so for now I am simply limiting the frames to those that actually exist in the texture
			for (int i < framesY) {
				AnimationFrame frame = animation.frames[i];

				uvs[frame.index].index = frame.index;
			}

			// A horrible hack because once again, this whole animation code is fundamentally broken
			for (var uv in ref uvs) {
				packer.Add(.(.(frameWidth, frameHeight), 4), &uv.x, &uv.y);
			}

			textures.Add(.(new .(path), uvs, frameWidth, animation));
		}

		delete metadata;
		
		return (.) textures.Count - 1;
	}

	private uint16 AddMissingTexture() {
		if (missingTexture.HasValue) return missingTexture.Value;

		ImageInfo image = Meteorite.INSTANCE.resources.ReadImageInfo("missing.png");

		UV[] uvs = new .[1];
		packer.Add(image, &uvs[0].x, &uvs[0].y);
		textures.Add(.(new .("missing.png"), uvs, image.Width, null));

		missingTexture = (.) (textures.Count - 1);
		return missingTexture.Value;
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

			if (texture.uvs.Count == 1) {
				atlas.Put(image, texture.uvs[0].x, texture.uvs[0].y);
			}
			else {
				uint8[] data = new .[texture.size * texture.size * 4];

				for (let uv in texture.uvs) {
					int y = uv.index * texture.size;
					for (int i < texture.size) {
						Internal.MemCpy(&data[(i * texture.size) * 4], &image.pixels[(y + i) * image.Width * 4], texture.size * 4);
					}
					atlas.Put(scope .(.(texture.size, texture.size), 4, &data[0], false), uv.x, uv.y);
				}

				delete data;
			}

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

		buffer = Gfx.Buffers.Create("Textures", .Uniform, .Mappable, (.) (sizeof(BufferTexture) * bufferData.Count));
		buffer.Upload(&bufferData[0], buffer.Size);
		
		DeleteAndNullify!(textures);
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