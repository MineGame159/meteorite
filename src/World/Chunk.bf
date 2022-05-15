using System;
using FastNoiseLite;

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

		public BlockState[SIZE * SIZE * SIZE] blocks;
		public Biome[64] biomes;

		public BlockState Get(int x, int y, int z) {
			BlockState block = blocks[SIZE * SIZE * z + SIZE * y + x];
			return block == null ? Blocks.AIR.defaultBlockState : block;
		}

		public void Set(int x, int y, int z, BlockState b) {
			blocks[SIZE * SIZE * z + SIZE * y + x] = b;
		}

		public Biome GetBiome(int x, int y, int z) => biomes[((y >> 2) & 3) << 4 | ((z >> 2) & 3) << 2 | ((x >> 2) & 3)];
		public void SetBiome(int x, int y, int z, Biome b) => biomes[4 * 4 * z + 4 * y + x] = b;
	}

	class Chunk {
		public enum Status {
			Ready,
			Building,
			Upload
		}

		private static StdAllocator ALLOC = .();

		public World world;
		public ChunkPos pos;

		private Section[] sections;

		public Status status = .Ready;
		public bool dirty;
		public Mesh mesh ~ delete _;
		public Mesh meshTransparent ~ delete _;

		public Vec3f min, max;

		public this(World world, ChunkPos pos) {
			this.world = world;
			this.pos = pos;
			this.sections = new Section[world.SectionCount];

			this.min = .(pos.x * Section.SIZE, 0, pos.z * Section.SIZE);
			this.max = .(pos.x * Section.SIZE + Section.SIZE, 0, pos.z * Section.SIZE + Section.SIZE);
		}

		public ~this() {
			for (int i < sections.Count) {
				Section section = sections[i];
				if (section != null) delete:ALLOC section;
			}

			delete sections;
		}

		public BlockState Get(int x, int y, int z) {
			Section section = sections[y / Section.SIZE];
			return section == null ? Blocks.AIR.defaultBlockState : section.Get(x, y % Section.SIZE, z);
		}

		public void Set(int x, int y, int z, BlockState block) {
			Section section = sections[y / Section.SIZE];

			if (section == null) {
				section = new:ALLOC Section();
				sections[y / Section.SIZE] = section;
			}

			section.Set(x, y % Section.SIZE, z, block);
			dirty = true;
		}

		public Section GetSection(int i) => sections[i];

		public void Load(NetBuffer packet) {
			packet.ReadNbt().Dispose();

			int size = packet.ReadVarInt();

			int minY = sections.Count * Section.SIZE;
			int maxY = 0;

			for (int i < sections.Count) {
				Section section = sections[i];
				if (section == null) {
					section = new:ALLOC .();
					sections[i] = section;
				}

				packet.Skip(2); // Block Count

				{
					// Blocks States
					int bitsPerEntry = packet.ReadUByte();
					int32[] palette = null;

					if (bitsPerEntry == 0) {
						// Single entry
						palette = new int32[1] (packet.ReadVarInt());
					}
					else if (bitsPerEntry <= 8) {
						// Indirect
						if (bitsPerEntry < 4) bitsPerEntry = 4;

						int paletteSize = packet.ReadVarInt();
						palette = new int32[paletteSize];

						for (int j < paletteSize) palette[j] = packet.ReadVarInt();
					}
					else {
						// Direct
						Log.Error("No idea what to do here");
					}

					int dataSize = packet.ReadVarInt();

					if (palette == null) packet.Skip(dataSize * 8);
					else {
						if (bitsPerEntry == 0) {
							BlockState blockState = Blocks.BLOCKSTATES.GetValueOrDefault(palette[0]);
							if (blockState != null && blockState != Blocks.AIR.defaultBlockState) {
								for (int j < Section.SIZE * Section.SIZE * Section.SIZE) section.blocks[j] = blockState;
							}
						}
						else if (bitsPerEntry <= 8) {
							int x = 0;
							int y = 0;
							int z = 0;
							int count = 0;
							int64 dataBitmask = GenerateBitMask(bitsPerEntry);

							for (int j < dataSize) {
								int64 l = packet.ReadLong();
								int entries = 64 / bitsPerEntry;
								bool end = false;

								for (int k < entries) {
									int32 blockIndex = (.) ((l >> k * bitsPerEntry) & dataBitmask);

									BlockState blockState = Blocks.BLOCKSTATES.GetValueOrDefault(palette[blockIndex]);
									if (blockState == null) blockState = Blocks.AIR.defaultBlockState;
									section.Set(x, y, z, blockState);

									if (blockState.block != Blocks.AIR) {
										int by = i * Section.SIZE + y;

										if (by < minY) minY = by;
										if (by > maxY) maxY = by;
									}

									count++;
									if (count == Section.SIZE * Section.SIZE * Section.SIZE) {
										end = true;
										break;
									}

									x++;
									if (x >= Section.SIZE) {
									    x = 0;
									    z++;

									    if (z >= Section.SIZE) {
									        z = 0;
									        y++;
									    }
									}
								}

								if (end) break;
							}
						}
						else packet.Skip(dataSize * 8);

						delete palette;
					}
				}
				{
					// Biomes
					int bitsPerEntry = packet.ReadUByte();
					int32[] palette = null;

					if (bitsPerEntry == 0) {
						// Single entry
						palette = new int32[1] (packet.ReadVarInt());
					}
					else if (bitsPerEntry <= 3) {
						// Indirect
						int paletteSize = packet.ReadVarInt();
						palette = new int32[paletteSize];

						for (int j < paletteSize) palette[j] = packet.ReadVarInt();
					}
					else {
						// Direct
						Log.Error("No idea what to do here");
					}

					int dataSize = packet.ReadVarInt();

					if (palette == null) packet.Skip(dataSize * 8);
					else {
						if (bitsPerEntry == 0) {
							Biome biome = Biomes.BIOMES.GetValueOrDefault(palette[0]);
							if (biome == null) biome = Biomes.BIOMES[0];

							for (int j < 64) section.biomes[j] = biome;
							
						}
						else {
							int x = 0;
							int y = 0;
							int z = 0;
							int count = 0;
							int64 dataBitmask = GenerateBitMask(bitsPerEntry);

							for (int j < dataSize) {
								int64 l = packet.ReadLong();
								int entries = 64 / bitsPerEntry;
								bool end = false;

								for (int k < entries) {
									int32 blockIndex = (.) ((l >> k * bitsPerEntry) & dataBitmask);

									Biome biome = Biomes.BIOMES.GetValueOrDefault(palette[blockIndex]);
									if (biome == null) biome = Biomes.BIOMES[0];
									section.SetBiome(x, y, z, biome);

									count++;
									if (count == 64) {
										end = true;
										break;
									}

									x++;
									if (x >= Section.SIZE) {
									    x = 0;
									    z++;

									    if (z >= Section.SIZE) {
									        z = 0;
									        y++;
									    }
									}
								}

								if (end) break;
							}
						}

						delete palette;
					}
				}
			}

			min.y = minY - 1;
			max.y = maxY + 1;

			dirty = true;
		}

		private static int64 GenerateBitMask(int bits) {
		    int64 bitmask = 0;

		    for (int i < bits) {
		        bitmask |= 1 << i;
		    }

		    return bitmask;
		}
	}
}