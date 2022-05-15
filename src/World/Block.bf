using System;
using System.Collections;

namespace Meteorite {
	class Block : IEnumerable<BlockState> {
		public String id ~ delete _;
		public bool transparent, cross;

		private List<BlockState> blockStates ~ DeleteContainerAndItems!(_);
		public BlockState defaultBlockState;

		public this(StringView id, bool transparent, bool cross = false) {
			this.id = new .(id);
			this.transparent = transparent;
			this.cross = cross;
			this.blockStates = new .();
		}

		public void AddBlockState(BlockState blockState) {
			blockStates.Add(blockState);
			if (defaultBlockState == null) defaultBlockState = blockState;
		}

		public List<BlockState>.Enumerator GetEnumerator() => blockStates.GetEnumerator();
	}

	class BlockState {
		public Block block;
		public Model model ~ delete _;

		private List<Property> properties ~ delete _;

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
	}
}