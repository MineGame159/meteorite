using System;
using System.IO;
using System.Collections;
using stb_image;

namespace Meteorite {
	class Biome : this(float temperature, float downfall, Color waterColor) {
		private static Color[] GRASS_COLORS ~ delete _;
		private static Color[] FOLIAGE_COLORS ~ delete _;

		public static void LoadColormaps() {
			{
				// Grass
				List<uint8> buffer = new .();
				File.ReadAll("assets/textures/colormap/grass.png", buffer);

				int32 width = 0, height = 0, comp = 0;
				uint8* data = stbi.stbi_load_from_memory(buffer.Ptr, (.) buffer.Count, &width, &height, &comp, 4);

				GRASS_COLORS = new Color[width * height];
				Internal.MemCpy(&GRASS_COLORS[0], data, GRASS_COLORS.Count * 4);

				stbi.stbi_image_free(data);
				delete buffer;
			}
			{
				// Foliage
				List<uint8> buffer = new .();
				File.ReadAll("assets/textures/colormap/foliage.png", buffer);

				int32 width = 0, height = 0, comp = 0;
				uint8* data = stbi.stbi_load_from_memory(buffer.Ptr, (.) buffer.Count, &width, &height, &comp, 4);

				FOLIAGE_COLORS = new Color[width * height];
				Internal.MemCpy(&FOLIAGE_COLORS[0], data, FOLIAGE_COLORS.Count * 4);

				stbi.stbi_image_free(data);
				delete buffer;
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