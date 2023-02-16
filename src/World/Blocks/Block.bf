using System;
using System.Collections;

using Cacti;

namespace Meteorite;

enum BlockOffsetType {
	None,
	XZ,
	XYZ
}

class Block : IRegistryEntry, IEnumerable<BlockState> {
	private ResourceKey key;
	private int32 id;

	public bool transparent;

	private List<BlockState> blockStates ~ DeleteContainerAndItems!(_);
	public BlockState defaultBlockState;

	public ResourceKey Key => key;
	public int32 Id => id;

	[AllowAppend]
	public this(ResourceKey key, int32 id, BlockSettings settings) {
		ResourceKey _key = append .(key);

		this.key = _key;
		this.id = id;

		this.transparent = settings.transparent;

		this.blockStates = new .();
	}

	public void AddBlockState(BlockState blockState) {
		blockStates.Add(blockState);
		if (defaultBlockState == null) defaultBlockState = blockState;
	}

	public List<BlockState>.Enumerator GetEnumerator() => blockStates.GetEnumerator();

	public virtual VoxelShape GetShape(BlockState blockState) => blockState.[Friend]shapes.shape;
	public virtual VoxelShape GetCollisionShape(BlockState blockState) => blockState.[Friend]shapes.collision;
	public virtual VoxelShape GetRaycastShape(BlockState blockState) => blockState.[Friend]shapes.raycast;
}

class BlockState : IRegistryEntry {
	public Block block;
	private int32 id;

	public uint8 luminance;
	public bool emissive;
	public BlockOffsetType offsetType;

	public Model model ~ delete _;

	public List<Property> properties ~ delete _;

	private VoxelShapes.Shapes shapes;

	public ResourceKey Key => block.Key;
	public int32 Id => id;

	public this(Block block, List<Property> properties) {
		this.block = block;
		this.properties = properties;
		this.shapes = VoxelShapes.Get(this);
	}

	public VoxelShape Shape => block.GetShape(this);
	public VoxelShape CollisionShape => block.GetCollisionShape(this);
	public VoxelShape RaycastShape => block.GetRaycastShape(this);

	public Vec3f GetOffset(int x, int z) {
		if (offsetType == .None) return .ZERO;

		// TODO: There are like 2 blocks which have these 2 values changed
		float maxHorizontalOffset = 0.25f;
		float maxVerticalOffset = 0.2f;

		int64 seed = Utils.GetSeed(x, 0, z);

		return .(
			Math.Clamp((((seed & 15L) / 15f) - 0.5f) * 0.5f, -maxHorizontalOffset, maxHorizontalOffset),
			offsetType == .XYZ ? (((seed >> 4 & 15L) / 15.0f) - 1f) * maxVerticalOffset : 0f,
			Math.Clamp((((seed >> 8 & 15L) / 15f) - 0.5f) * 0.5f, -maxHorizontalOffset, maxHorizontalOffset)
		);
	}

	public Property GetProperty(StringView name) {
		for (let property in properties) {
			if (property.info.name == name) return property;
		}

		return default;
	}
}

class BlockSettings {
	public bool transparent;
	public bool hasCollision = true;

	public Self Transparent() {
		transparent = true;
		return this;
	}

	public Self NoCollision() {
		hasCollision = false;
		return this;
	}
}