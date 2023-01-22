using System;

namespace Meteorite;

class BlockItem : Item {
	public Block block;

	public this(StringView id, int32 rawId, Block block, ItemSettings settings) : base(id, rawId, settings) {
		this.block = block;
	}
}