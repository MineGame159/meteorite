using System;

namespace Meteorite {
	struct ChunkPos : IHashable {
		public int32 x;
		public int32 z;

		public this(int x, int z) {
			this.x = (.) x;
			this.z = (.) z;
		}

		public int GetHashCode() => Utils.CombineHashCode(x, z);
	}

	class Section {
		public const int SIZE = 16;

		public PalettedContainer<BlockState> blocks ~ delete _;
		public PalettedContainer<Biome> biomes ~ delete _;

		[Inline]
		public BlockState Get(int x, int y, int z) => blocks.Get(x, y, z);
		
		[Inline]
		public Biome GetBiome(int x, int y, int z) => biomes.Get((x >> 2) & 3, (y >> 2) & 3, (z >> 2) & 3);
	}

	class Chunk {
		public enum Status {
			Ready,
			Building,
			Upload
		}

		public World world;
		public ChunkPos pos;

		private Section[] sections;

		public Status status = .Ready;
		public bool dirty, firstBuild = true;
		public Mesh mesh ~ delete _;
		public Mesh meshTransparent ~ delete _;

		public double yOffset;
		public bool goingDown;

		public Vec3f min, max;

		public this(World world, ChunkPos pos, Section[] sections) {
			this.world = world;
			this.pos = pos;
			this.sections = sections;

			this.dirty = true;

			this.min = .(pos.x * Section.SIZE, 0, pos.z * Section.SIZE);
			this.max = .(pos.x * Section.SIZE + Section.SIZE, 0, pos.z * Section.SIZE + Section.SIZE);
		}

		public ~this() {
			for (int i < sections.Count) {
				Section section = sections[i];
				if (section != null) delete section;
			}

			delete sections;
		}
		
		[Inline]
		public BlockState Get(int x, int y, int z) {
			return sections[y / Section.SIZE].Get(x, y % Section.SIZE, z);
		}

		[Inline]
		public Biome GetBiome(int x, int y, int z) {
			return sections[y / Section.SIZE].GetBiome(x, y % Section.SIZE, z);
		}

		[Inline]
		public Section GetSection(int i) => sections[i];
	}
}