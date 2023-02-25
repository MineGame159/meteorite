using System;
using System.Collections;

using Cacti;

namespace Meteorite;

enum BlockColorType {
	case Grass;
	case Foliage;
	case Water;
	case Redstone;
	case Stem;

	case Custom(Color color);
}

static class BlockColors {
	private static Dictionary<Block, BlockColorType> colors = new .() ~ delete _;
	private static Color[16] redstoneColors;

	public static void Init() {
		Meteorite.INSTANCE.resources.ReadJsons("data/block_colors.json", scope (json) => {
			for (let pair in json.AsObject) {
				Block block = BuiltinRegistries.BLOCKS.Get(scope .("minecraft", pair.key));

				if (pair.value.IsString) {
					String str = pair.value.AsString;

					if (str == "grass") colors[block] = .Grass;
					else if (str == "foliage") colors[block] = .Foliage;
					else if (str == "water") colors[block] = .Water;
					else if (str == "redstone") colors[block] = .Redstone;
					else if (str == "stem") colors[block] = .Stem;
				}
				else if (pair.value.IsNumber) {
					colors[block] = .Custom(.((.) pair.value.AsNumber));
				}
			}

			json.Dispose();
		});

		for (int i < redstoneColors.Count) {
			float f = i / 15f;
			float r = f * 0.6f + (f > 0f ? 0.4f : 0.3f);
			float g = Math.Clamp(f * f * 0.7f - 0.5f, 0f, 1f);
			float b = Math.Clamp(f * f * 0.6f - 0.7f, 0f, 1f);
			redstoneColors[i] = .(r, g, b);
		}
	}

	public static Color Get(BlockState blockState, Biome biome) {
		Block key;
		BlockColorType type;
		
		if (colors.TryGet(blockState.block, out key, out type)) {
			switch (type) {
			case .Grass:   return biome.GetGrassColor();
			case .Foliage: return biome.GetFoliageColor();
			case .Water:   return biome.waterColor;

			case .Redstone:
				int power = blockState.GetProperty("power").value;
				return redstoneColors[power];

			case .Stem:
				int age = blockState.GetProperty("age").value;
				return .((uint8) (age * 32), (uint8) (255 - age * 8), (uint8) (age * 4));

			case .Custom(let color): return color;
			default:
			}
		}

		return .(255, 255, 255);
	}
}