using System;
using System.Collections;

using Cacti;

namespace Meteorite;

class BlockEntityType : IRegistryEntry {
	public typealias Factory = delegate BlockEntity(Vec3i);

	private ResourceKey key;
	private int32 id;

	public Block[] blocks ~ delete _;

	private Factory factory ~ delete _;

	public ResourceKey Key => key;
	public int32 Id => id;

	[AllowAppend]
	public this(StringView key, int32 id, Block[] blocks, Factory factory) {
		ResourceKey _key = append .(key);

		this.key = _key;
		this.id = id;
		this.blocks = blocks;
		this.factory = factory;
	}

	public BlockEntity Create(Vec3i pos) {
		return factory != null ? factory(pos) : null;
	}
}