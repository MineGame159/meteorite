using System;

namespace Meteorite {
	static class BlockColors {
		public static Color Get(Block block, Biome biome) {
			// TODO: Implement this properly

			switch (block) {
			case Blocks.WATER: return biome.waterColor;
			case Blocks.GRASS_BLOCK, Blocks.GRASS, Blocks.TALL_GRASS: return biome.GetGrassColor();
			case Blocks.OAK_LEAVES, Blocks.SPRUCE_LEAVES, Blocks.BIRCH_LEAVES, Blocks.JUNGLE_LEAVES, Blocks.ACACIA_LEAVES, Blocks.DARK_OAK_LEAVES: return biome.GetFoliageColor();
			case Blocks.SUGAR_CANE: return biome.GetGrassColor();
			}

			return .(255, 255, 255);
		}
	}
}