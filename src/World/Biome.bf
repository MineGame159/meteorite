using System;

namespace Meteorite {
	class Biome : this(float temperature, float downfall, Color waterColor, Color skyColor, Color fogColor) {
		private static Color[] GRASS_COLORS ~ delete _;
		private static Color[] FOLIAGE_COLORS ~ delete _;

		public static void LoadColormaps() {
			{
				// Grass
				Image image = Meteorite.INSTANCE.resources.ReadImage("colormap/grass.png");

				GRASS_COLORS = new Color[image.width * image.height];
				Internal.MemCpy(&GRASS_COLORS[0], image.data, GRASS_COLORS.Count * 4);

				delete image;
			}
			{
				// Foliage
				Image image = Meteorite.INSTANCE.resources.ReadImage("colormap/foliage.png");

				FOLIAGE_COLORS = new Color[image.width * image.height];
				Internal.MemCpy(&FOLIAGE_COLORS[0], image.data, FOLIAGE_COLORS.Count * 4);

				delete image;
			}
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
}