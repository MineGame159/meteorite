using System;
using System.Collections;

namespace Meteorite {
	class Block : IEnumerable<BlockState> {
		public String id ~ delete _;
		public bool transparent;

		private List<BlockState> blockStates ~ DeleteContainerAndItems!(_);
		public BlockState defaultBlockState;

		public this(StringView id, BlockSettings settings) {
			this.id = new .(id);
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

	class BlockState : IID {
		public Block block;
		public int32 id { get; set; };

		public Model model ~ delete _;

		public List<Property> properties ~ delete _;

		private VoxelShapes.Shapes shapes;

		public this(Block block, List<Property> properties) {
			this.block = block;
			this.properties = properties;
			this.shapes = VoxelShapes.Get(this);
		}

		public VoxelShape Shape => block.GetShape(this);
		public VoxelShape CollisionShape => block.GetCollisionShape(this);
		public VoxelShape RaycastShape => block.GetRaycastShape(this);

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
}