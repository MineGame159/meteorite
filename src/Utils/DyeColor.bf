using System;
using System.Collections;

using Cacti;

namespace Meteorite;

static class DyeColor {
	private static Dictionary<String, Color> COLORS = new .() ~ DeleteDictionaryAndKeys!(_);

	public static Color BLACK = Add("black", .(0, 0, 0));
	public static Color DAKR_BLUE = Add("dark_blue", .(0, 0, 170));
	public static Color DARK_GREEN = Add("dark_green", .(0, 170, 0));
	public static Color DARK_CYAN = Add("dark_cyan", .(0, 170, 170));
	public static Color DARK_RED = Add("dark_red", .(170, 0, 0));
	public static Color PURPLE = Add("purple", .(170, 0, 170));
	public static Color GOLD = Add("gold", .(255, 170, 0));
	public static Color GRAY = Add("gray", .(170, 170, 170));
	public static Color DARK_GRAY = Add("dark_gray", .(85, 85, 85));
	public static Color BLUE = Add("blue", .(85, 85, 255));
	public static Color GREEN = Add("green", .(85, 255, 85));
	public static Color CYAN = Add("aqua", .(85, 255, 255));
	public static Color RED = Add("red", .(225, 85, 85));
	public static Color PINK = Add("light_purple", .(255, 85, 255));
	public static Color YELLOW = Add("yellow", .(255, 255, 85));
	public static Color WHITE = Add("white", .(255, 255, 255));

	public static Result<Color> Get(StringView name) {
		Color color;

		if (COLORS.TryGetValueAlt(name, out color)) return color;
		return .Err;
	}

	private static Color Add(StringView name, Color color) {
		COLORS[new .(name)] = color;
		return color;
	}
}