using System;
using System.Collections;

namespace Meteorite {
	extension Blocks {
		public static BlockState[] BLOCKSTATES = new .[MAX_ID + 1] ~ delete _;

		private static Json IDS;
		private static String STR1, STR2;

		private static void BeforeRegister() {
			IDS = Meteorite.INSTANCE.resources.ReadJson("data/blockstates.json");
			STR1 = new .();
			STR2 = new .();
		}

		private static void AfterRegister() {
			IDS.Dispose();
			delete STR1;
			delete STR2;
		}

		private static int32 GetId(BlockState blockState) {
			STR1.Append(blockState.block.id);

			for (int i < blockState.properties.Count) {
				Property property = blockState.properties[i];
				property.GetValueString(STR2);

				STR1.Append(i == 0 ? ';' : ',');
				STR1.Append(property.info.name);
				STR1.Append(':');
				STR1.Append(STR2);

				STR2.Clear();
			}

			int32 id = (.) IDS.GetInt(STR1, 0);

			STR1.Clear();
			return id;
		}

		private static void LoopProperties(Block block, PropertyInfo[] properties, int[] values, int i) {
			PropertyInfo info = properties[i];

			for (int j = info.min; j <= info.max; j++) {
				values[i] = j;

				if (properties.Count - 1 == i) {
					List<Property> props = new .(properties.Count);
					for (int k < properties.Count) props.Add(.(properties[k], values[k]));

					BlockState blockState = new .(block, props);
					blockState.id = GetId(blockState);

					block.AddBlockState(blockState);
					
					BLOCKSTATES[blockState.id] = blockState;
				}
				else LoopProperties(block, properties, values, i + 1);
			}
		}

		private static Block Register(Block block, params PropertyInfo[] properties) {
			Registry.BLOCKS.Register(block.id, block);

			if (properties.IsEmpty) {
				BlockState blockState = new .(block, new .());
				block.AddBlockState(blockState);

				BLOCKSTATES[GetId(blockState)] = blockState;
			}
			else {
				int[] values = scope int[properties.Count];
				LoopProperties(block, properties, values, 0);
			}

			return block;
		}
	}
}