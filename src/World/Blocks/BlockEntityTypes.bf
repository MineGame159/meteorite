using System;

namespace Meteorite;

static class BlockEntityTypes {
    public static BlockEntityType[] TYPES = new .[38] ~ delete _;

	public static BlockEntityType FURNACE = Create("furnace", 0, new Block[] (Blocks.FURNACE)) ~ delete _;
	public static BlockEntityType CHEST = Create("chest", 1, new Block[] (Blocks.CHEST), new (pos) => new ChestBlockEntity(pos)) ~ delete _;
	public static BlockEntityType TRAPPED_CHEST = Create("trapped_chest", 2, new Block[] (Blocks.TRAPPED_CHEST), new (pos) => new TrappedChestBlockEntity(pos)) ~ delete _;
	public static BlockEntityType ENDER_CHEST = Create("ender_chest", 3, new Block[] (Blocks.ENDER_CHEST), new (pos) => new EnderChestBlockEntity(pos)) ~ delete _;
	public static BlockEntityType JUKEBOX = Create("jukebox", 4, new Block[] (Blocks.JUKEBOX)) ~ delete _;
	public static BlockEntityType DISPENSER = Create("dispenser", 5, new Block[] (Blocks.DISPENSER)) ~ delete _;
	public static BlockEntityType DROPPER = Create("dropper", 6, new Block[] (Blocks.DROPPER)) ~ delete _;
	public static BlockEntityType SIGN = Create("sign", 7, new Block[] (Blocks.OAK_SIGN, Blocks.SPRUCE_SIGN, Blocks.BIRCH_SIGN, Blocks.ACACIA_SIGN, Blocks.JUNGLE_SIGN, Blocks.DARK_OAK_SIGN, Blocks.OAK_WALL_SIGN, Blocks.SPRUCE_WALL_SIGN, Blocks.BIRCH_WALL_SIGN, Blocks.ACACIA_WALL_SIGN, Blocks.JUNGLE_WALL_SIGN, Blocks.DARK_OAK_WALL_SIGN, Blocks.CRIMSON_SIGN, Blocks.CRIMSON_WALL_SIGN, Blocks.WARPED_SIGN, Blocks.WARPED_WALL_SIGN, Blocks.MANGROVE_SIGN, Blocks.MANGROVE_WALL_SIGN, Blocks.BAMBOO_SIGN, Blocks.BAMBOO_WALL_SIGN)) ~ delete _;
	public static BlockEntityType HANGING_SIGN = Create("hanging_sign", 8, new Block[] (Blocks.OAK_HANGING_SIGN, Blocks.SPRUCE_HANGING_SIGN, Blocks.BIRCH_HANGING_SIGN, Blocks.ACACIA_HANGING_SIGN, Blocks.JUNGLE_HANGING_SIGN, Blocks.DARK_OAK_HANGING_SIGN, Blocks.CRIMSON_HANGING_SIGN, Blocks.WARPED_HANGING_SIGN, Blocks.MANGROVE_HANGING_SIGN, Blocks.BAMBOO_HANGING_SIGN, Blocks.OAK_WALL_HANGING_SIGN, Blocks.SPRUCE_WALL_HANGING_SIGN, Blocks.BIRCH_WALL_HANGING_SIGN, Blocks.ACACIA_WALL_HANGING_SIGN, Blocks.JUNGLE_WALL_HANGING_SIGN, Blocks.DARK_OAK_WALL_HANGING_SIGN, Blocks.CRIMSON_WALL_HANGING_SIGN, Blocks.WARPED_WALL_HANGING_SIGN, Blocks.MANGROVE_WALL_HANGING_SIGN, Blocks.BAMBOO_WALL_HANGING_SIGN)) ~ delete _;
	public static BlockEntityType MOB_SPAWNER = Create("mob_spawner", 9, new Block[] (Blocks.SPAWNER)) ~ delete _;
	public static BlockEntityType PISTON = Create("piston", 10, new Block[] (Blocks.MOVING_PISTON)) ~ delete _;
	public static BlockEntityType BREWING_STAND = Create("brewing_stand", 11, new Block[] (Blocks.BREWING_STAND)) ~ delete _;
	public static BlockEntityType ENCHANTING_TABLE = Create("enchanting_table", 12, new Block[] (Blocks.ENCHANTING_TABLE)) ~ delete _;
	public static BlockEntityType END_PORTAL = Create("end_portal", 13, new Block[] (Blocks.END_PORTAL)) ~ delete _;
	public static BlockEntityType BEACON = Create("beacon", 14, new Block[] (Blocks.BEACON)) ~ delete _;
	public static BlockEntityType SKULL = Create("skull", 15, new Block[] (Blocks.SKELETON_SKULL, Blocks.SKELETON_WALL_SKULL, Blocks.CREEPER_HEAD, Blocks.CREEPER_WALL_HEAD, Blocks.DRAGON_HEAD, Blocks.DRAGON_WALL_HEAD, Blocks.ZOMBIE_HEAD, Blocks.ZOMBIE_WALL_HEAD, Blocks.WITHER_SKELETON_SKULL, Blocks.WITHER_SKELETON_WALL_SKULL, Blocks.PLAYER_HEAD, Blocks.PLAYER_WALL_HEAD, Blocks.PIGLIN_HEAD, Blocks.PIGLIN_WALL_HEAD)) ~ delete _;
	public static BlockEntityType DAYLIGHT_DETECTOR = Create("daylight_detector", 16, new Block[] (Blocks.DAYLIGHT_DETECTOR)) ~ delete _;
	public static BlockEntityType HOPPER = Create("hopper", 17, new Block[] (Blocks.HOPPER)) ~ delete _;
	public static BlockEntityType COMPARATOR = Create("comparator", 18, new Block[] (Blocks.COMPARATOR)) ~ delete _;
	public static BlockEntityType BANNER = Create("banner", 19, new Block[] (Blocks.WHITE_BANNER, Blocks.ORANGE_BANNER, Blocks.MAGENTA_BANNER, Blocks.LIGHT_BLUE_BANNER, Blocks.YELLOW_BANNER, Blocks.LIME_BANNER, Blocks.PINK_BANNER, Blocks.GRAY_BANNER, Blocks.LIGHT_GRAY_BANNER, Blocks.CYAN_BANNER, Blocks.PURPLE_BANNER, Blocks.BLUE_BANNER, Blocks.BROWN_BANNER, Blocks.GREEN_BANNER, Blocks.RED_BANNER, Blocks.BLACK_BANNER, Blocks.WHITE_WALL_BANNER, Blocks.ORANGE_WALL_BANNER, Blocks.MAGENTA_WALL_BANNER, Blocks.LIGHT_BLUE_WALL_BANNER, Blocks.YELLOW_WALL_BANNER, Blocks.LIME_WALL_BANNER, Blocks.PINK_WALL_BANNER, Blocks.GRAY_WALL_BANNER, Blocks.LIGHT_GRAY_WALL_BANNER, Blocks.CYAN_WALL_BANNER, Blocks.PURPLE_WALL_BANNER, Blocks.BLUE_WALL_BANNER, Blocks.BROWN_WALL_BANNER, Blocks.GREEN_WALL_BANNER, Blocks.RED_WALL_BANNER, Blocks.BLACK_WALL_BANNER)) ~ delete _;
	public static BlockEntityType STRUCTURE_BLOCK = Create("structure_block", 20, new Block[] (Blocks.STRUCTURE_BLOCK)) ~ delete _;
	public static BlockEntityType END_GATEWAY = Create("end_gateway", 21, new Block[] (Blocks.END_GATEWAY)) ~ delete _;
	public static BlockEntityType COMMAND_BLOCK = Create("command_block", 22, new Block[] (Blocks.COMMAND_BLOCK, Blocks.CHAIN_COMMAND_BLOCK, Blocks.REPEATING_COMMAND_BLOCK)) ~ delete _;
	public static BlockEntityType SHULKER_BOX = Create("shulker_box", 23, new Block[] (Blocks.SHULKER_BOX, Blocks.BLACK_SHULKER_BOX, Blocks.BLUE_SHULKER_BOX, Blocks.BROWN_SHULKER_BOX, Blocks.CYAN_SHULKER_BOX, Blocks.GRAY_SHULKER_BOX, Blocks.GREEN_SHULKER_BOX, Blocks.LIGHT_BLUE_SHULKER_BOX, Blocks.LIGHT_GRAY_SHULKER_BOX, Blocks.LIME_SHULKER_BOX, Blocks.MAGENTA_SHULKER_BOX, Blocks.ORANGE_SHULKER_BOX, Blocks.PINK_SHULKER_BOX, Blocks.PURPLE_SHULKER_BOX, Blocks.RED_SHULKER_BOX, Blocks.WHITE_SHULKER_BOX, Blocks.YELLOW_SHULKER_BOX)) ~ delete _;
	public static BlockEntityType BED = Create("bed", 24, new Block[] (Blocks.RED_BED, Blocks.BLACK_BED, Blocks.BLUE_BED, Blocks.BROWN_BED, Blocks.CYAN_BED, Blocks.GRAY_BED, Blocks.GREEN_BED, Blocks.LIGHT_BLUE_BED, Blocks.LIGHT_GRAY_BED, Blocks.LIME_BED, Blocks.MAGENTA_BED, Blocks.ORANGE_BED, Blocks.PINK_BED, Blocks.PURPLE_BED, Blocks.WHITE_BED, Blocks.YELLOW_BED)) ~ delete _;
	public static BlockEntityType CONDUIT = Create("conduit", 25, new Block[] (Blocks.CONDUIT)) ~ delete _;
	public static BlockEntityType BARREL = Create("barrel", 26, new Block[] (Blocks.BARREL)) ~ delete _;
	public static BlockEntityType SMOKER = Create("smoker", 27, new Block[] (Blocks.SMOKER)) ~ delete _;
	public static BlockEntityType BLAST_FURNACE = Create("blast_furnace", 28, new Block[] (Blocks.BLAST_FURNACE)) ~ delete _;
	public static BlockEntityType LECTERN = Create("lectern", 29, new Block[] (Blocks.LECTERN)) ~ delete _;
	public static BlockEntityType BELL = Create("bell", 30, new Block[] (Blocks.BELL), new (pos) => new BellBlockEntity(pos)) ~ delete _;
	public static BlockEntityType JIGSAW = Create("jigsaw", 31, new Block[] (Blocks.JIGSAW)) ~ delete _;
	public static BlockEntityType CAMPFIRE = Create("campfire", 32, new Block[] (Blocks.CAMPFIRE, Blocks.SOUL_CAMPFIRE)) ~ delete _;
	public static BlockEntityType BEEHIVE = Create("beehive", 33, new Block[] (Blocks.BEE_NEST, Blocks.BEEHIVE)) ~ delete _;
	public static BlockEntityType SCULK_SENSOR = Create("sculk_sensor", 34, new Block[] (Blocks.SCULK_SENSOR)) ~ delete _;
	public static BlockEntityType SCULK_CATALYST = Create("sculk_catalyst", 35, new Block[] (Blocks.SCULK_CATALYST)) ~ delete _;
	public static BlockEntityType SCULK_SHRIEKER = Create("sculk_shrieker", 36, new Block[] (Blocks.SCULK_SHRIEKER)) ~ delete _;
	public static BlockEntityType CHISELED_BOOKSHELF = Create("chiseled_bookshelf", 37, new Block[] (Blocks.CHISELED_BOOKSHELF)) ~ delete _;

    private static BlockEntityType Create(StringView key, int32 id, Block[] blocks, BlockEntityType.Factory factory = null) {
        BlockEntityType type = new .(key, id, blocks, factory);
        TYPES[id] = type;
        return type;
    }
}
