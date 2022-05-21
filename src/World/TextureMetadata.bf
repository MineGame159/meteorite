using System;
using System.Collections;

namespace Meteorite {
	class TextureMetadata {
		public TextureAnimationMetadata animation ~ delete _;

		public static TextureMetadata Parse(StringView path) {
			Result<Json> result = Meteorite.INSTANCE.resources.ReadJson(scope $"textures/{path}.mcmeta");
			if (result == .Err) return null;
			Json json = result.Get();

			TextureMetadata metadata = new .();

			if (json.Contains("animation")) {
				Json j = json["animation"];
				TextureAnimationMetadata animation = new .();

				animation.width = j.GetInt("width", -1);
				animation.height = j.GetInt("height", -1);
				animation.frameTime = j.GetInt("frametime", 1);
				animation.interpolate = j.GetBool("interpolate");

				if (j.Contains("frames")) {
					animation.frames = new .();

					for (let j2 in j["frames"].AsArray) {
						if (j2.IsNumber) {
							animation.frames.Add(.((.) j2.AsNumber, -1));
						}
						else if (j2.IsObject) {
							animation.frames.Add(.(j2.GetInt("index", 0), j2.GetInt("time", -1)));
						}
						else {
							Log.Error("{}.mcmeta invalid animation frame", path);
						}
					}
				}

				metadata.animation = animation;
			}

			json.Dispose();
			return metadata;
		}
	}

	class TextureAnimationMetadata {
		public int width, height;
		public int frameTime;
		public bool interpolate;
		public List<AnimationFrame> frames ~ delete _;

		public (int, int) GetFrameSize(int width, int height) {
			let (w, h) = CalculateFrameSize(width, height);

			if (IsDivisionInteger(width, w) && IsDivisionInteger(height, h)) {
				return (w, h);
			}
			else {
				Log.Error("Image size {}, {} is not multiply of frame size {}, {}", width, height, w, h);
				return (0, 0);
			}
		}

		private bool IsDivisionInteger(int valMul, int val) => valMul / val * val == valMul;

		private (int, int) CalculateFrameSize(int width, int height) {
			if (this.width != -1) {
				return this.height != -1 ? (this.width, this.height) : (this.width, height);
			}
			else if (this.height != -1) {
				return (width, this.height);
			}
			else {
				int i = Math.Min(width, height);
				return (i, i);
			}
		}

		public int GetFrameWidth(int width) => this.width == -1 ? width : this.width;
		public int GetFrameHeight(int height) => this.height == -1 ? height : this.height;
	}

	struct AnimationFrame : this(int index, int time) {
		public int GetTime(int time) => this.time == -1 ? time : this.time;
	}
}