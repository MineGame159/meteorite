using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

extension Blocks {
	public static BlockState[] BLOCKSTATES = new .[MAX_ID + 1] ~ delete _;

	private static JsonTree JSON;
	private static String STR1, STR2;

	private static Tracy.Zone ZONE;

	private static void BeforeRegister() {
		JSON = Meteorite.INSTANCE.resources.ReadJson("data/block_states.json");
		STR1 = new .();
		STR2 = new .();
	}

	private static void AfterRegister() {
		delete JSON;
		delete STR1;
		delete STR2;
	}

	private static void ReadOptions(BlockState blockState) {
		// Build property string
		STR1.Append(blockState.block.Key.Path);
		defer STR1.Clear();

		for (int i < blockState.properties.Count) {
			Property property = blockState.properties[i];
			property.GetValueString(STR2);

			STR1.Append(i == 0 ? ';' : ',');
			STR1.Append(property.info.name);
			STR1.Append(':');
			STR1.Append(STR2);

			STR2.Clear();
		}

		// Read options
		Json json = JSON.root[STR1];

		if (json.IsObject) {
			blockState.[Friend]id = (.) json.GetInt("id", 0);
			blockState.luminance = (.) json.GetInt("luminance", 0);
			blockState.emissive = json.GetBool("emissive");

			if (json.Contains("offset_type")) {
				blockState.offsetType = Enum.Parse<BlockOffsetType>(json["offset_type"].AsString, true);
			}
		}
		else {
			blockState.[Friend]id = (.) json.AsNumber;
		}
	}

	private static void LoopProperties(Block block, PropertyInfo[] properties, int[] values, int i) {
		PropertyInfo info = properties[i];

		for (int j = info.min; j <= info.max; j++) {
			values[i] = j;

			if (properties.Count - 1 == i) {
				List<Property> props = new .(properties.Count);
				for (int k < properties.Count) props.Add(.(properties[k], values[k]));

				BlockState blockState = new .(block, props);
				ReadOptions(blockState);

				block.AddBlockState(blockState);
				
				BLOCKSTATES[blockState.Id] = blockState;
			}
			else LoopProperties(block, properties, values, i + 1);
		}
	}

	private static Block Register(Block block, params PropertyInfo[] properties) {
		BuiltinRegistries.BLOCKS.Register(block);

		if (properties.IsEmpty) {
			BlockState blockState = new .(block, new .());
			ReadOptions(blockState);
			
			block.AddBlockState(blockState);

			BLOCKSTATES[blockState.Id] = blockState;
		}
		else {
			int[] values = scope int[properties.Count];
			LoopProperties(block, properties, values, 0);
		}

		return block;
	}
}