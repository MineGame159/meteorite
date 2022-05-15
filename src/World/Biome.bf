using System;
using System.IO;
using StbImageBeef;

namespace Meteorite {
	class Biome : this(float temperature, float downfall, Color waterColor) {
		private static Color[] GRASS_COLORS ~ delete _;
		private static Color[] FOLIAGE_COLORS ~ delete _;

		public static void LoadColormaps() {
			{
				// Grass
				FileStream fs = scope .();
				fs.Open("assets/textures/colormap/grass.png", .Read);
				ImageResult image = ImageResult.FromStream(fs, .RedGreenBlueAlpha);

				GRASS_COLORS = new Color[image.Width * image.Height];
				Internal.MemCpy(&GRASS_COLORS[0], image.Data, GRASS_COLORS.Count * 4);

				delete image;
			}
			{
				// Foliage
				FileStream fs = scope .();
				fs.Open("assets/textures/colormap/foliage.png", .Read);
				ImageResult image = ImageResult.FromStream(fs, .RedGreenBlueAlpha);

				FOLIAGE_COLORS = new Color[image.Width * image.Height];
				Internal.MemCpy(&FOLIAGE_COLORS[0], image.Data, FOLIAGE_COLORS.Count * 4);

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