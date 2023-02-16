using System;

namespace Meteorite;

static class BuiltinRegistries {
	public static Registry<Block> BLOCKS = new .(scope .("minecraft:block")) ~ delete _;
	public static Registry<Item> ITEMS = new .(scope .("minecraft:")) ~ delete _;
	public static Registry<Biome> BIOMES = new .(scope .("minecraft:worldgen/biome")) ~ delete _;
	public static Registry<EntityType> ENTITY_TYPES = new .(scope .("minecraft:entity_types")) ~ delete _;
}