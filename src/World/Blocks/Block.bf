using System;
using System.Collections;

namespace Meteorite {
	class Block : IEnumerable<BlockState> {
		public static VoxelShape BLOCK_SHAPE = .Block() ~ delete _;

		public String id ~ delete _;
		public bool transparent, hasCollision;

		private List<BlockState> blockStates ~ DeleteContainerAndItems!(_);
		public BlockState defaultBlockState;

		public this(StringView id, BlockSettings settings) {
			this.id = new .(id);
			this.transparent = settings.transparent;
			this.hasCollision = settings.hasCollision;

			this.blockStates = new .();
		}

		public void AddBlockState(BlockState blockState) {
			blockStates.Add(blockState);
			if (defaultBlockState == null) defaultBlockState = blockState;
		}

		public List<BlockState>.Enumerator GetEnumerator() => blockStates.GetEnumerator();

		public virtual VoxelShape GetShape() => BLOCK_SHAPE;

		public virtual VoxelShape GetCollisionShape() => hasCollision ? GetShape() : .EMPTY;
	}

	class BlockState : IID {
		public Block block;
		public int32 id { get; set; };

		public Model model ~ delete _;

		public List<Property> properties ~ delete _;

		public this(Block block, List<Property> properties) {
			this.block = block;
			this.properties = properties;
		}

		public Property GetProperty(StringView name) {
			for (let property in properties) {
				if (property.info.name == name) return property;
			}

			return default;
		}

		public VoxelShape GetShape() => block.GetShape();

		public VoxelShape GetCollisionShape() => block.GetCollisionShape();
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