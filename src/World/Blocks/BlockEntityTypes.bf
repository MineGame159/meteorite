using System;

namespace Meteorite {
	static class BlockEntityTypes {
		public static BlockEntityType[] TYPES = new .[38] ~ delete _;

		public static BlockEntityType FURNACE = Create(0, "furnace", new Block[] (Blocks.FURNACE)) ~ delete _;
		public static BlockEntityType CHEST = Create(1, "chest", new Block[] (Blocks.CHEST), new (pos) => new ChestBlockEntity(pos)) ~ delete _;
		public static BlockEntityType TRAPPED_CHEST = Create(2, "trapped_chest", new Block[] (Blocks.TRAPPED_CHEST), new (pos) => new TrappedChestBlockEntity(pos)) ~ delete _;
		public static BlockEntityType ENDER_CHEST = Create(3, "ender_chest", new Block[] (Blocks.ENDER_CHEST), new (pos) => new EnderChestBlockEntity(pos)) ~ delete _;
		public static BlockEntityType JUKEBOX = Create(4, "jukebox", new Block[] (Blocks.JUKEBOX)) ~ delete _;
		public static BlockEntityType DISPENSER = Create(5, "dispenser", new Block[] (Blocks.DISPENSER)) ~ delete _;
		public static BlockEntityType DROPPER = Create(6, "dropper", new Block[] (Blocks.DROPPER)) ~ delete _;
		public static BlockEntityType SIGN = Create(7, "sign", new Block[] (Blocks.OAK_SIGN, Blocks.SPRUCE_SIGN, Blocks.BIRCH_SIGN, Blocks.ACACIA_SIGN, Blocks.JUNGLE_SIGN, Blocks.DARK_OAK_SIGN, Blocks.OAK_WALL_SIGN, Blocks.SPRUCE_WALL_SIGN, Blocks.BIRCH_WALL_SIGN, Blocks.ACACIA_WALL_SIGN, Blocks.JUNGLE_WALL_SIGN, Blocks.DARK_OAK_WALL_SIGN, Blocks.CRIMSON_SIGN, Blocks.CRIMSON_WALL_SIGN, Blocks.WARPED_SIGN, Blocks.WARPED_WALL_SIGN, Blocks.MANGROVE_SIGN, Blocks.MANGROVE_WALL_SIGN, Blocks.BAMBOO_SIGN, Blocks.BAMBOO_WALL_SIGN)) ~ delete _;
		public static BlockEntityType HANGING_SIGN = Create(8, "hanging_sign", new Block[] (Blocks.OAK_HANGING_SIGN, Blocks.SPRUCE_HANGING_SIGN, Blocks.BIRCH_HANGING_SIGN, Blocks.ACACIA_HANGING_SIGN, Blocks.JUNGLE_HANGING_SIGN, Blocks.DARK_OAK_HANGING_SIGN, Blocks.CRIMSON_HANGING_SIGN, Blocks.WARPED_HANGING_SIGN, Blocks.MANGROVE_HANGING_SIGN, Blocks.BAMBOO_HANGING_SIGN, Blocks.OAK_WALL_HANGING_SIGN, Blocks.SPRUCE_WALL_HANGING_SIGN, Blocks.BIRCH_WALL_HANGING_SIGN, Blocks.ACACIA_WALL_HANGING_SIGN, Blocks.JUNGLE_WALL_HANGING_SIGN, Blocks.DARK_OAK_WALL_HANGING_SIGN, Blocks.CRIMSON_WALL_HANGING_SIGN, Blocks.WARPED_WALL_HANGING_SIGN, Blocks.MANGROVE_WALL_HANGING_SIGN, Blocks.BAMBOO_WALL_HANGING_SIGN)) ~ delete _;
		public static BlockEntityType MOB_SPAWNER = Create(9, "mob_spawner", new Block[] (Blocks.SPAWNER)) ~ delete _;
		public static BlockEntityType PISTON = Create(10, "piston", new Block[] (Blocks.MOVING_PISTON)) ~ delete _;
		public static BlockEntityType BREWING_STAND = Create(11, "brewing_stand", new Block[] (Blocks.BREWING_STAND)) ~ delete _;
		public static BlockEntityType ENCHANTING_TABLE = Create(12, "enchanting_table", new Block[] (Blocks.ENCHANTING_TABLE)) ~ delete _;
		public static BlockEntityType END_PORTAL = Create(13, "end_portal", new Block[] (Blocks.END_PORTAL)) ~ delete _;
		public static BlockEntityType BEACON = Create(14, "beacon", new Block[] (Blocks.BEACON)) ~ delete _;
		public static BlockEntityType SKULL = Create(15, "skull", new Block[] (Blocks.SKELETON_SKULL, Blocks.SKELETON_WALL_SKULL, Blocks.CREEPER_HEAD, Blocks.CREEPER_WALL_HEAD, Blocks.DRAGON_HEAD, Blocks.DRAGON_WALL_HEAD, Blocks.ZOMBIE_HEAD, Blocks.ZOMBIE_WALL_HEAD, Blocks.WITHER_SKELETON_SKULL, Blocks.WITHER_SKELETON_WALL_SKULL, Blocks.PLAYER_HEAD, Blocks.PLAYER_WALL_HEAD, Blocks.PIGLIN_HEAD, Blocks.PIGLIN_WALL_HEAD)) ~ delete _;
		public static BlockEntityType DAYLIGHT_DETECTOR = Create(16, "daylight_detector", new Block[] (Blocks.DAYLIGHT_DETECTOR)) ~ delete _;
		public static BlockEntityType HOPPER = Create(17, "hopper", new Block[] (Blocks.HOPPER)) ~ delete _;
		public static BlockEntityType COMPARATOR = Create(18, "comparator", new Block[] (Blocks.COMPARATOR)) ~ delete _;
		public static BlockEntityType BANNER = Create(19, "banner", new Block[] (Blocks.WHITE_BANNER, Blocks.ORANGE_BANNER, Blocks.MAGENTA_BANNER, Blocks.LIGHT_BLUE_BANNER, Blocks.YELLOW_BANNER, Blocks.LIME_BANNER, Blocks.PINK_BANNER, Blocks.GRAY_BANNER, Blocks.LIGHT_GRAY_BANNER, Blocks.CYAN_BANNER, Blocks.PURPLE_BANNER, Blocks.BLUE_BANNER, Blocks.BROWN_BANNER, Blocks.GREEN_BANNER, Blocks.RED_BANNER, Blocks.BLACK_BANNER, Blocks.WHITE_WALL_BANNER, Blocks.ORANGE_WALL_BANNER, Blocks.MAGENTA_WALL_BANNER, Blocks.LIGHT_BLUE_WALL_BANNER, Blocks.YELLOW_WALL_BANNER, Blocks.LIME_WALL_BANNER, Blocks.PINK_WALL_BANNER, Blocks.GRAY_WALL_BANNER, Blocks.LIGHT_GRAY_WALL_BANNER, Blocks.CYAN_WALL_BANNER, Blocks.PURPLE_WALL_BANNER, Blocks.BLUE_WALL_BANNER, Blocks.BROWN_WALL_BANNER, Blocks.GREEN_WALL_BANNER, Blocks.RED_WALL_BANNER, Blocks.BLACK_WALL_BANNER)) ~ delete _;
		public static BlockEntityType STRUCTURE_BLOCK = Create(20, "structure_block", new Block[] (Blocks.STRUCTURE_BLOCK)) ~ delete _;
		public static BlockEntityType END_GATEWAY = Create(21, "end_gateway", new Block[] (Blocks.END_GATEWAY)) ~ delete _;
		public static BlockEntityType COMMAND_BLOCK = Create(22, "command_block", new Block[] (Blocks.COMMAND_BLOCK, Blocks.CHAIN_COMMAND_BLOCK, Blocks.REPEATING_COMMAND_BLOCK)) ~ delete _;
		public static BlockEntityType SHULKER_BOX = Create(23, "shulker_box", new Block[] (Blocks.SHULKER_BOX, Blocks.BLACK_SHULKER_BOX, Blocks.BLUE_SHULKER_BOX, Blocks.BROWN_SHULKER_BOX, Blocks.CYAN_SHULKER_BOX, Blocks.GRAY_SHULKER_BOX, Blocks.GREEN_SHULKER_BOX, Blocks.LIGHT_BLUE_SHULKER_BOX, Blocks.LIGHT_GRAY_SHULKER_BOX, Blocks.LIME_SHULKER_BOX, Blocks.MAGENTA_SHULKER_BOX, Blocks.ORANGE_SHULKER_BOX, Blocks.PINK_SHULKER_BOX, Blocks.PURPLE_SHULKER_BOX, Blocks.RED_SHULKER_BOX, Blocks.WHITE_SHULKER_BOX, Blocks.YELLOW_SHULKER_BOX)) ~ delete _;
		public static BlockEntityType BED = Create(24, "bed", new Block[] (Blocks.RED_BED, Blocks.BLACK_BED, Blocks.BLUE_BED, Blocks.BROWN_BED, Blocks.CYAN_BED, Blocks.GRAY_BED, Blocks.GREEN_BED, Blocks.LIGHT_BLUE_BED, Blocks.LIGHT_GRAY_BED, Blocks.LIME_BED, Blocks.MAGENTA_BED, Blocks.ORANGE_BED, Blocks.PINK_BED, Blocks.PURPLE_BED, Blocks.WHITE_BED, Blocks.YELLOW_BED)) ~ delete _;
		public static BlockEntityType CONDUIT = Create(25, "conduit", new Block[] (Blocks.CONDUIT)) ~ delete _;
		public static BlockEntityType BARREL = Create(26, "barrel", new Block[] (Blocks.BARREL)) ~ delete _;
		public static BlockEntityType SMOKER = Create(27, "smoker", new Block[] (Blocks.SMOKER)) ~ delete _;
		public static BlockEntityType BLAST_FURNACE = Create(28, "blast_furnace", new Block[] (Blocks.BLAST_FURNACE)) ~ delete _;
		public static BlockEntityType LECTERN = Create(29, "lectern", new Block[] (Blocks.LECTERN)) ~ delete _;
		public static BlockEntityType BELL = Create(30, "bell", new Block[] (Blocks.BELL), new (pos) => new BellBlockEntity(pos)) ~ delete _;
		public static BlockEntityType JIGSAW = Create(31, "jigsaw", new Block[] (Blocks.JIGSAW)) ~ delete _;
		public static BlockEntityType CAMPFIRE = Create(32, "campfire", new Block[] (Blocks.CAMPFIRE, Blocks.SOUL_CAMPFIRE)) ~ delete _;
		public static BlockEntityType BEEHIVE = Create(33, "beehive", new Block[] (Blocks.BEE_NEST, Blocks.BEEHIVE)) ~ delete _;
		public static BlockEntityType SCULK_SENSOR = Create(34, "sculk_sensor", new Block[] (Blocks.SCULK_SENSOR)) ~ delete _;
		public static BlockEntityType SCULK_CATALYST = Create(35, "sculk_catalyst", new Block[] (Blocks.SCULK_CATALYST)) ~ delete _;
		public static BlockEntityType SCULK_SHRIEKER = Create(36, "sculk_shrieker", new Block[] (Blocks.SCULK_SHRIEKER)) ~ delete _;
		public static BlockEntityType CHISELED_BOOKSHELF = Create(37, "chiseled_bookshelf", new Block[] (Blocks.CHISELED_BOOKSHELF)) ~ delete _;

		private static BlockEntityType Create(int32 rawId, StringView id, Block[] blocks, BlockEntityType.Factory factory = null) {
			BlockEntityType type = new .(id, blocks, factory);
			TYPES[rawId] = type;
			return type;
		}
	}
}
