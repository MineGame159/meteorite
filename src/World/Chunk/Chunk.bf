using System;
using System.Collections;

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

		public int y;
		public Chunk chunk;

		public PalettedContainer<BlockState> blocks ~ delete _;
		public PalettedContainer<Biome> biomes ~ delete _;

		public this(int y) {
			this.y = y;
		}

		[Inline]
		public BlockState Get(int x, int y, int z) => blocks.Get(x, y, z);

		[Inline]
		public void Set(int x, int y, int z, BlockState blockState) {
			blocks.Set(x, y, z, blockState);

			int by = this.y * SIZE + y;
			if (by < chunk.min.y) chunk.min.y = by;
			else if (by > chunk.max.y) chunk.max.y = by;

			chunk.dirty = true;
		}
		
		[Inline]
		public Biome GetBiome(int x, int y, int z) => biomes.Get((x >> 2) & 3, (y >> 2) & 3, (z >> 2) & 3);
	}

	class Chunk {
		public enum Status {
			Ready,
			Building,
			Upload
		}

		private static Dictionary<Vec3i, BlockEntity> EMPTY = new .(0) ~ delete _;

		public World world;
		public ChunkPos pos;

		private Section[] sections;
		private Dictionary<Vec3i, BlockEntity> blockEntities ~ DeleteDictionaryAndValues!(_);

		public Status status = .Ready;
		public bool dirty, firstBuild = true;
		public Mesh mesh ~ delete _;
		public Mesh meshTransparent ~ delete _;

		public double yOffset;
		public bool goingDown;

		public Vec3f min, max;

		public this(World world, ChunkPos pos, Section[] sections, Dictionary<Vec3i, BlockEntity> blockEntities) {
			this.world = world;
			this.pos = pos;
			this.sections = sections;
			this.blockEntities = blockEntities;

			this.dirty = true;

			this.min = .(pos.x * Section.SIZE, 0, pos.z * Section.SIZE);
			this.max = .(pos.x * Section.SIZE + Section.SIZE, 0, pos.z * Section.SIZE + Section.SIZE);

			for (Section section in sections) section.chunk = this;
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
		public void Set(int x, int y, int z, BlockState blockState) {
			sections[y / Section.SIZE].Set(x, y % Section.SIZE, z, blockState);
		}

		[Inline]
		public Biome GetBiome(int x, int y, int z) {
			return sections[y / Section.SIZE].GetBiome(x, y % Section.SIZE, z);
		}

		[Inline]
		public Section GetSection(int i) => sections[i];
		
		public Dictionary<Vec3i, BlockEntity>.ValueEnumerator BlockEntities => (blockEntities != null ? blockEntities : EMPTY).Values;

		public int BlockEntityCount => blockEntities != null ? blockEntities.Count : 0;

		public BlockEntity GetBlockEntity(int x, int y, int z) => blockEntities != null ? blockEntities.GetValueOrDefault(.(x, y, z)) : null;

		public void RemoveBlockEntity(int x, int y, int z) {
			if (blockEntities != null) blockEntities.Remove(Vec3i(x, y, z));
		}
	}
}