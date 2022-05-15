using System;
using System.Collections;

namespace Meteorite {
	static class Properties {
		public static PropertyInfo SNOWY = .Bool("snowy") ~ delete _;
		public static PropertyInfo LEVEL0_15 = .Int("level", 0, 15) ~ delete _;
		public static PropertyInfo AXIS = .Enum("axis", "x", "y", "z") ~ delete _;
		public static PropertyInfo LIT = .Bool("lit") ~ delete _;
		public static PropertyInfo DISTANCE1_7 = .Int("distance", 1, 7) ~ delete _;
		public static PropertyInfo PERSISTENT = .Bool("persistent") ~ delete _;
		public static PropertyInfo LAYERS1_8 = .Int("layers", 1, 8) ~ delete _;
		public static PropertyInfo FACING = .Enum("facing", "north", "south", "west", "east") ~ delete _;
		public static PropertyInfo BOTTOM = .Bool("bottom") ~ delete _;
		public static PropertyInfo DISTANCE0_7 = .Int("distance", 0, 7) ~ delete _;
		public static PropertyInfo WATERLOGGED = .Bool("waterlogged") ~ delete _;
		public static PropertyInfo SIGNAL_FIRE = .Bool("signal_fire") ~ delete _;
		public static PropertyInfo EAST = .Bool("east") ~ delete _;
		public static PropertyInfo NORTH = .Bool("north") ~ delete _;
		public static PropertyInfo SOUTH = .Bool("south") ~ delete _;
		public static PropertyInfo WEST = .Bool("west") ~ delete _;
		public static PropertyInfo SLAB_TYPE = .Enum("type", "top", "bottom", "double") ~ delete _;
		public static PropertyInfo BLOCK_HALF = .Enum("half", "top", "bottom") ~ delete _;
		public static PropertyInfo STAIRS_SHAPE = .Enum("shape", "straight", "inner_left", "inner_right", "outer_left", "outer_right") ~ delete _;
		public static PropertyInfo DOUBLE_BLOCK_HALF = .Enum("half", "upper", "lower") ~ delete _;
		public static PropertyInfo AGE_25 = .Int("age", 0, 25) ~ delete _;
		public static PropertyInfo MOISTURE = .Int("moisture", 0, 7) ~ delete _;
		public static PropertyInfo VERTICAL_DIRECTION = .Enum("vertical_direction", "up", "down") ~ delete _;
		public static PropertyInfo THICKNESS = .Enum("thickness", "tip_merge", "tip", "frustum", "middle", "base") ~ delete _;
		public static PropertyInfo HORIZONTAL_FACING = .Enum("facing", "north", "east", "south", "west") ~ delete _;
		public static PropertyInfo OPEN = .Bool("open") ~ delete _;
		public static PropertyInfo POWERED = .Bool("powered") ~ delete _;
	}

	class PropertyInfo {
		public StringView name;
		public int min, max;
		public List<StringView> names ~ delete _;

		public this(StringView name, int min, int max, params StringView[] names) {
			this.name = name;
			this.min = min;
			this.max = max;
			
			this.names = new .(names.Count);
			this.names.AddRange(names);
		}

		public static PropertyInfo Bool(StringView name) => new .(name, 0, 1, "true", "false");
		public static PropertyInfo Int(StringView name, int min, int max) => new .(name, min, max);
		public static PropertyInfo Enum(StringView name, params StringView[] names) => new .(name, 0, names.Count - 1, params names);
	}

	struct Property : this(PropertyInfo info, int value) {
		public void GetValueString(String str) {
			if (info.names.IsEmpty) value.ToString(str);
			else str.Append(info.names[value]);
		}
	}
}