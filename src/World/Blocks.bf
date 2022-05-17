using System;
using System.Collections;

namespace Meteorite {
	static class Blocks {
		public static Texture ATLAS ~ delete _;
		public static BlockState[] BLOCKSTATES ~ delete _;

		private static Dictionary<StringView, int32> STARTING_IDS;

		public static Block AIR;

		public static Block BEDROCK;
		public static Block STONE;
		public static Block INFESTED_STONE;
		public static Block GRANITE;
		public static Block DIORITE;
		public static Block ANDESITE;
		public static Block DEEPSLATE;
		public static Block TUFF;
		public static Block COBBLESTONE;
		public static Block MOSSY_COBBLESTONE;
		public static Block DRIPSTONE;
		public static Block POINTED_DRIPSTONE;

		public static Block DIRT;
		public static Block GRASS_BLOCK;
		public static Block SAND;
		public static Block GRAVEL;
		public static Block CLAY;
		public static Block PODZOL;
		public static Block DIRT_PATH;
		public static Block FARMLAND;

		public static Block OAK_LOG;
		public static Block SPRUCE_LOG;
		public static Block BIRCH_LOG;
		public static Block JUNGLE_LOG;
		public static Block ACACIA_LOG;
		public static Block DARK_OAK_LOG;

		public static Block STRIPPED_OAK_LOG;
		public static Block STRIPPED_SPRUCE_LOG;
		public static Block STRIPPED_BIRCH_LOG;
		public static Block STRIPPED_JUNGLE_LOG;
		public static Block STRIPPED_ACACIA_LOG;
		public static Block STRIPPED_DARK_OAK_LOG;

		public static Block OAK_PLANKS;
		public static Block SPRUCE_PLANKS;
		public static Block BIRCH_PLANKS;
		public static Block JUNGLE_PLANKS;
		public static Block ACACIA_PLANKS;
		public static Block DARK_OAK_PLANKS;
		public static Block CRIMSON_PLANKS;
		public static Block WARPED_PLANKS;

		public static Block OAK_SLAB;
		public static Block SPRUCE_SLAB;
		public static Block BIRCH_SLAB;
		public static Block JUNGLE_SLAB;
		public static Block ACACIA_SLAB;
		public static Block DARK_OAK_SLAB;
		public static Block CRIMSON_SLAB;
		public static Block WARPED_SLAB;

		public static Block OAK_STAIRS;
		public static Block SPRUCE_STAIRS;
		public static Block BIRCH_STAIRS;
		public static Block JUNGLE_STAIRS;
		public static Block ACACIA_STAIRS;
		public static Block DARK_OAK_STAIRS;
		public static Block CRIMSON_STAIRS;
		public static Block WARPED_STAIRS;

		public static Block OAK_TRAPDOOR;
		public static Block SPRUCE_TRAPDOOR;
		public static Block BIRCH_TRAPDOOR;
		public static Block JUNGLE_TRAPDOOR;
		public static Block ACACIA_TRAPDOOR;
		public static Block DARK_OAK_TRAPDOOR;
		public static Block CRIMSON_TRAPDOOR;
		public static Block WARPED_TRAPDOOR;

		public static Block OAK_FENCE;
		public static Block SPRUCE_FENCE;
		public static Block BIRCH_FENCE;
		public static Block JUNGLE_FENCE;
		public static Block ACACIA_FENCE;
		public static Block DARK_OAK_FENCE;
		public static Block CRIMSON_FENCE;
		public static Block WARPED_FENCE;
		public static Block NETHER_BRICK_FENCE;

		public static Block OAK_LEAVES;
		public static Block SPRUCE_LEAVES;
		public static Block BIRCH_LEAVES;
		public static Block JUNGLE_LEAVES;
		public static Block ACACIA_LEAVES;
		public static Block DARK_OAK_LEAVES;
		public static Block AZALEA_LEAVES;
		public static Block FLOWERING_AZALEA_LEAVES;

		public static Block WATER;
		public static Block LAVA;

		public static Block COAL_ORE;
		public static Block DEEPSLATE_COAL_ORE;
		public static Block COPPER_ORE;
		public static Block DEEPSLATE_COPPER_ORE;
		public static Block IRON_ORE;
		public static Block DEEPSLATE_IRON_ORE;
		public static Block GOLD_ORE;
		public static Block DEEPSLATE_GOLD_ORE;
		public static Block LAPIS_ORE;
		public static Block DEEPSLATE_LAPIS_ORE;
		public static Block REDSTONE_ORE;
		public static Block DEEPSLATE_REDSTONE_ORE;
		public static Block DIAMOND_ORE;
		public static Block DEEPSLATE_DIAMOND_ORE;
		public static Block EMERALD_ORE;
		public static Block DEEPSLATE_EMERALD_ORE;
		public static Block NETHER_GOLD_ORE;
		public static Block NETHER_QUARTZ_ORE;

		public static Block SNOW_BLOCK;
		public static Block POWDER_SNOW;
		public static Block SNOW;

		public static Block TORCH;
		public static Block WALL_TORCH;
		public static Block REDSTONE_TORCH;
		public static Block REDSTONE_WALL_TORCH;
		public static Block SOUL_TORCH;
		public static Block SOUL_WALL_TORCH;

		public static Block HAY_BLOCK;
		public static Block CAULDRON;
		public static Block ANVIL;
		public static Block SCAFFOLDING;
		public static Block CAMPFIRE;
		public static Block BOOKSHELF;

		public static Block GRASS;
		public static Block TALL_GRASS;
		public static Block DANDELION;
		public static Block POPPY;
		public static Block BLUE_ORCHID;
		public static Block AZURE_BLUET;
		public static Block RED_TULIP;
		public static Block ORANGE_TULIP;
		public static Block WHITE_TULIP;
		public static Block PINK_TULIP;
		public static Block OXEYE_DAISY;
		public static Block CORNFLOWER;
		public static Block LILY_OF_THE_VALLEY;
		public static Block SEAGRASS;
		public static Block TALL_SEAGRASS;
		public static Block KELP;
		public static Block KELP_PLANT;

		private static void LoopProperties(Block block, int32* id, PropertyInfo[] properties, int[] values, int i) {
			PropertyInfo info = properties[i];

			for (int j = info.min; j <= info.max; j++) {
				values[i] = j;

				if (properties.Count - 1 == i) {
					List<Property> props = new .(properties.Count);
					for (int k < properties.Count) props.Add(.(properties[k], values[k]));

					BlockState blockState = new .(block, props);
					block.AddBlockState(blockState);

					BLOCKSTATES[(*id)++] = blockState;
				}
				else LoopProperties(block, id, properties, values, i + 1);
			}
		}

		private static Block Register(Block block, params PropertyInfo[] properties) {
			int32 startingId = STARTING_IDS[block.id];
			Registry.BLOCKS.Register(block.id, block);

			if (properties.IsEmpty) {
				BlockState blockState = new .(block, new .());
				block.AddBlockState(blockState);

				BLOCKSTATES[startingId] = blockState;
			}
			else {
				int[] values = scope int[properties.Count];
				LoopProperties(block, &startingId, properties, values, 0);
			}

			return block;
		}

		public static void Register() {
			// Get starting ids
			Json json = JsonParser.ParseFile("assets/blocks.json");
			BLOCKSTATES = new .[(.) json["__max_id__"].AsNumber];
			STARTING_IDS = new .((.) json.AsObject.Count);
			for (let pair in json.AsObject) STARTING_IDS[pair.key.Substring(10)] = (.) pair.value.AsNumber;

			// Register blocks
			AIR = Register(new .("air", true));

			BEDROCK = Register(new .("bedrock", false));
			STONE = Register(new .("stone", false));
			INFESTED_STONE = Register(new .("infested_stone", false));
			GRANITE = Register(new .("granite", false));
			DIORITE = Register(new .("diorite", false));
			ANDESITE = Register(new .("andesite", false));
			DEEPSLATE = Register(new .("deepslate", false), Properties.AXIS);
			TUFF = Register(new .("tuff", false));
			COBBLESTONE = Register(new .("cobblestone", false));
			MOSSY_COBBLESTONE = Register(new .("mossy_cobblestone", false));
			DRIPSTONE = Register(new .("dripstone_block", false));
			POINTED_DRIPSTONE = Register(new .("pointed_dripstone", true, true), Properties.THICKNESS, Properties.VERTICAL_DIRECTION, Properties.WATERLOGGED);

			DIRT = Register(new .("dirt", false));
			GRASS_BLOCK = Register(new .("grass_block", false), Properties.SNOWY);
			SAND = Register(new .("sand", false));
			GRAVEL = Register(new .("gravel", false));
			CLAY = Register(new .("clay", false));
			PODZOL = Register(new .("podzol", false), Properties.SNOWY);
			DIRT_PATH = Register(new .("dirt_path", false));
			FARMLAND = Register(new .("farmland", false), Properties.MOISTURE);

			OAK_LOG = Register(new .("oak_log", false), Properties.AXIS);
			SPRUCE_LOG = Register(new .("spruce_log", false), Properties.AXIS);
			BIRCH_LOG = Register(new .("birch_log", false), Properties.AXIS);
			JUNGLE_LOG = Register(new .("jungle_log", false), Properties.AXIS);
			ACACIA_LOG = Register(new .("acacia_log", false), Properties.AXIS);
			DARK_OAK_LOG = Register(new .("dark_oak_log", false), Properties.AXIS);

			STRIPPED_OAK_LOG = Register(new .("stripped_oak_log", false), Properties.AXIS);
			STRIPPED_SPRUCE_LOG = Register(new .("stripped_spruce_log", false), Properties.AXIS);
			STRIPPED_BIRCH_LOG = Register(new .("stripped_birch_log", false), Properties.AXIS);
			STRIPPED_JUNGLE_LOG = Register(new .("stripped_jungle_log", false), Properties.AXIS);
			STRIPPED_ACACIA_LOG = Register(new .("stripped_acacia_log", false), Properties.AXIS);
			STRIPPED_DARK_OAK_LOG = Register(new .("stripped_dark_oak_log", false), Properties.AXIS);

			OAK_PLANKS = Register(new .("oak_planks", false));
			SPRUCE_PLANKS = Register(new .("spruce_planks", false));
			BIRCH_PLANKS = Register(new .("birch_planks", false));
			JUNGLE_PLANKS = Register(new .("jungle_planks", false));
			ACACIA_PLANKS = Register(new .("acacia_planks", false));
			DARK_OAK_PLANKS = Register(new .("dark_oak_planks", false));
			CRIMSON_PLANKS = Register(new .("crimson_planks", false));
			WARPED_PLANKS = Register(new .("warped_planks", false));

			OAK_SLAB = Register(new .("oak_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			SPRUCE_SLAB = Register(new .("spruce_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			BIRCH_SLAB = Register(new .("birch_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			JUNGLE_SLAB = Register(new .("jungle_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			ACACIA_SLAB = Register(new .("acacia_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			DARK_OAK_SLAB = Register(new .("dark_oak_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			CRIMSON_SLAB = Register(new .("crimson_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);
			WARPED_SLAB = Register(new .("warped_slab", false), Properties.SLAB_TYPE, Properties.WATERLOGGED);

			OAK_STAIRS = Register(new .("oak_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			SPRUCE_STAIRS = Register(new .("spruce_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			BIRCH_STAIRS = Register(new .("birch_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			JUNGLE_STAIRS = Register(new .("jungle_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			ACACIA_STAIRS = Register(new .("acacia_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			DARK_OAK_STAIRS = Register(new .("dark_oak_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			CRIMSON_STAIRS = Register(new .("crimson_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);
			WARPED_STAIRS = Register(new .("warped_stairs", false), Properties.FACING, Properties.BLOCK_HALF, Properties.STAIRS_SHAPE, Properties.WATERLOGGED);

			OAK_TRAPDOOR = Register(new .("oak_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			SPRUCE_TRAPDOOR = Register(new .("spruce_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			BIRCH_TRAPDOOR = Register(new .("birch_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			JUNGLE_TRAPDOOR = Register(new .("jungle_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			ACACIA_TRAPDOOR = Register(new .("acacia_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			DARK_OAK_TRAPDOOR = Register(new .("dark_oak_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			CRIMSON_TRAPDOOR = Register(new .("crimson_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);
			WARPED_TRAPDOOR = Register(new .("warped_trapdoor", true), Properties.HORIZONTAL_FACING, Properties.OPEN, Properties.BLOCK_HALF, Properties.POWERED, Properties.WATERLOGGED);

			OAK_FENCE = Register(new .("oak_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			/*SPRUCE_FENCE = Register(new .("spruce_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			BIRCH_FENCE = Register(new .("birch_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			JUNGLE_FENCE = Register(new .("jungle_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			ACACIA_FENCE = Register(new .("acacia_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			DARK_OAK_FENCE = Register(new .("dark_oak_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			CRIMSON_FENCE = Register(new .("crimson_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			WARPED_FENCE = Register(new .("warped_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);
			NETHER_BRICK_FENCE = Register(new .("nether_brick_fence", false), Properties.EAST, Properties.NORTH, Properties.SOUTH, Properties.WATERLOGGED, Properties.WEST);*/

			OAK_LEAVES = Register(new .("oak_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			SPRUCE_LEAVES = Register(new .("spruce_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			BIRCH_LEAVES = Register(new .("birch_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			JUNGLE_LEAVES = Register(new .("jungle_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			ACACIA_LEAVES = Register(new .("acacia_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			DARK_OAK_LEAVES = Register(new .("dark_oak_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			AZALEA_LEAVES = Register(new .("azalea_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);
			FLOWERING_AZALEA_LEAVES = Register(new .("flowering_azalea_leaves", true), Properties.DISTANCE1_7, Properties.PERSISTENT);

			WATER = Register(new .("water", true), Properties.LEVEL0_15);
			LAVA = Register(new .("lava", true), Properties.LEVEL0_15);

			COAL_ORE = Register(new .("coal_ore", false));
			DEEPSLATE_COAL_ORE = Register(new .("deepslate_coal_ore", false));
			COPPER_ORE = Register(new .("copper_ore", false));
			DEEPSLATE_COPPER_ORE = Register(new .("deepslate_copper_ore", false));
			IRON_ORE = Register(new .("iron_ore", false));
			DEEPSLATE_IRON_ORE = Register(new .("deepslate_iron_ore", false));
			GOLD_ORE = Register(new .("gold_ore", false));
			DEEPSLATE_GOLD_ORE = Register(new .("deepslate_gold_ore", false));
			LAPIS_ORE = Register(new .("lapis_ore", false));
			DEEPSLATE_LAPIS_ORE = Register(new .("deepslate_lapis_ore", false));
			REDSTONE_ORE = Register(new .("redstone_ore", false), Properties.LIT);
			DEEPSLATE_REDSTONE_ORE = Register(new .("deepslate_redstone_ore", false), Properties.LIT);
			DIAMOND_ORE = Register(new .("diamond_ore", false));
			DEEPSLATE_DIAMOND_ORE = Register(new .("deepslate_diamond_ore", false));
			EMERALD_ORE = Register(new .("emerald_ore", false));
			DEEPSLATE_EMERALD_ORE = Register(new .("deepslate_emerald_ore", false));
			NETHER_GOLD_ORE = Register(new .("nether_gold_ore", false));
			NETHER_QUARTZ_ORE = Register(new .("nether_quartz_ore", false));

			SNOW_BLOCK = Register(new .("snow_block", false));
			POWDER_SNOW = Register(new .("powder_snow", false));
			SNOW = Register(new .("snow", false), Properties.LAYERS1_8);

			TORCH = Register(new .("torch", false));
			WALL_TORCH = Register(new .("wall_torch", false), Properties.FACING);
			REDSTONE_WALL_TORCH = Register(new .("redstone_wall_torch", false), Properties.FACING, Properties.LIT);
			REDSTONE_TORCH = Register(new .("redstone_torch", false), Properties.LIT);
			SOUL_TORCH = Register(new .("soul_torch", false));
			SOUL_WALL_TORCH = Register(new .("soul_wall_torch", false), Properties.FACING);

			HAY_BLOCK = Register(new .("hay_block", false), Properties.AXIS);
			CAULDRON = Register(new .("cauldron", false));
			ANVIL = Register(new .("anvil", true), Properties.FACING);
			SCAFFOLDING = Register(new .("scaffolding", true), Properties.BOTTOM, Properties.DISTANCE0_7, Properties.WATERLOGGED);
			CAMPFIRE = Register(new .("campfire", false), Properties.FACING, Properties.LIT, Properties.SIGNAL_FIRE, Properties.WATERLOGGED);
			BOOKSHELF = Register(new .("bookshelf", false));

			GRASS = Register(new .("grass", true, true));
			TALL_GRASS = Register(new .("tall_grass", true, true), Properties.DOUBLE_BLOCK_HALF);
			DANDELION = Register(new .("dandelion", true, true));
			POPPY = Register(new .("poppy", true, true));
			BLUE_ORCHID = Register(new .("blue_orchid", true, true));
			AZURE_BLUET = Register(new .("azure_bluet", true, true));
			RED_TULIP = Register(new .("red_tulip", true, true));
			ORANGE_TULIP = Register(new .("orange_tulip", true, true));
			WHITE_TULIP = Register(new .("white_tulip", true, true));
			PINK_TULIP = Register(new .("pink_tulip", true, true));
			OXEYE_DAISY = Register(new .("oxeye_daisy", true, true));
			CORNFLOWER = Register(new .("cornflower", true, true));
			LILY_OF_THE_VALLEY = Register(new .("lily_of_the_valley", true, true));
			SEAGRASS = Register(new .("seagrass", true, true));
			TALL_SEAGRASS = Register(new .("tall_seagrass", true, true), Properties.DOUBLE_BLOCK_HALF);
			KELP = Register(new .("kelp", true, true), Properties.AGE_25);
			KELP_PLANT = Register(new .("kelp_plant", true, true));

			LoopColors(false, (color) => Register(new .(scope $"{color}_wool", false)));

			LoopColors(true, (color) => {
				if (color.IsEmpty) Register(new .("terracotta", false));
				else Register(new .(scope $"{color}_terracotta", false));
			});

			// Delete starting ids
			delete STARTING_IDS;
			json.Dispose();
		}

		private static void LoopColors(bool none, function void(StringView) callback) {
			if (none) callback("");
			callback("white");
			callback("orange");
			callback("magenta");
			callback("light_blue");
			callback("yellow");
			callback("lime");
			callback("pink");
			callback("gray");
			callback("light_gray");
			callback("cyan");
			callback("purple");
			callback("blue");
			callback("brown");
			callback("green");
			callback("red");
			callback("black");
		}
	}
}