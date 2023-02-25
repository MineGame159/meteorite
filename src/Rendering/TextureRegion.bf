using System;

using Cacti;

namespace Meteorite;

struct TextureRegion : this(Vec2i pos, Vec2i size, Vec2f uv1, Vec2f uv2) {
	public this(Vec2i pos, Vec2i size, Vec2i atlasSize) : this(
		pos,
		size,
		(Vec2f) pos / (Vec2f) atlasSize,
		(Vec2f) (pos + size) / (Vec2f) atlasSize
	) {}
}