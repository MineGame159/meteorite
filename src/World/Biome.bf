using System;

using Cacti;

namespace Meteorite;

class Biome : IRegistryEntry {
	private static Color[] GRASS_COLORS ~ delete _;
	private static Color[] FOLIAGE_COLORS ~ delete _;
	
	[Tracy.Profile]
	public static void LoadColormaps() {
		{
			// Grass
			Image image = Meteorite.INSTANCE.resources.ReadImage("colormap/grass.png");

			GRASS_COLORS = new Color[image.Width * image.Height];
			Internal.MemCpy(&GRASS_COLORS[0], image.pixels, GRASS_COLORS.Count * 4);

			delete image;
		}
		{
			// Foliage
			Image image = Meteorite.INSTANCE.resources.ReadImage("colormap/foliage.png");

			FOLIAGE_COLORS = new Color[image.Width * image.Height];
			Internal.MemCpy(&FOLIAGE_COLORS[0], image.pixels, FOLIAGE_COLORS.Count * 4);

			delete image;
		}
	}

	private ResourceKey key;
	private int32 id;

	public float temperature, downfall;
	public Color waterColor, skyColor, fogColor;

	public ResourceKey Key => key;
	public int32 Id => id;

	[AllowAppend]
	public this(ResourceKey key, int32 id, float temperature, float downfall, Color waterColor, Color skyColor, Color fogColor) {
		ResourceKey _key = append .(key);

		this.key = _key;
		this.id = id;

		this.temperature = temperature;
		this.downfall = downfall;
		this.waterColor = waterColor;
		this.skyColor = skyColor;
		this.fogColor = fogColor;
	}

	public Color GetGrassColor() {
		float temp = Math.Clamp(temperature, 0.0f, 1.0f);
		float humd = Math.Clamp(downfall, 0.0f, 1.0f);

		humd *= temp;
		int i = (int) ((1.0 - temp) * 255.0);
		int j = (int) ((1.0 - humd) * 255.0);
		int k = j << 8 | i;
		
		return k >= GRASS_COLORS.Count ? .(0, 0, 0, 255) : GRASS_COLORS[k];
	}

	public Color GetFoliageColor() {
		float temp = Math.Clamp(temperature, 0.0f, 1.0f);
		float humd = Math.Clamp(downfall, 0.0f, 1.0f);

		humd *= temp;
		int i = (int) ((1.0 - temp) * 255.0);
		int j = (int) ((1.0 - humd) * 255.0);
		int k = j << 8 | i;
		
		return k >= FOLIAGE_COLORS.Count ? .(0, 0, 0, 255) : FOLIAGE_COLORS[k];
	}
}