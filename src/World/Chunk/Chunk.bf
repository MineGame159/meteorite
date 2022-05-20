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

		public void Load(NetBuffer packet) {
			packet.ReadNbt().Dispose();

			packet.ReadVarInt(); // Size

			int minY = sections.Count * Section.SIZE;
			int maxY = 0;

			for (int i < sections.Count) {
				Section section = sections[i];
				if (section == null) {
					section = new .();
					sections[i] = section;
				}
				
				packet.Skip(2); // Block Count

				{
					// Blocks States
					uint8 bitsPerEntry = packet.ReadUByte();
					int32[] palette = ReadPalette(packet, bitsPerEntry, 8);
					int dataSize = packet.ReadVarInt();

					if (palette == null) packet.Skip(dataSize * 8);
					else {
						if (bitsPerEntry <= 8) {
							uint64[] data = new .[dataSize];
							for (int j < dataSize) data[j] = (.) packet.ReadLong();

							section.blocks = new .(Blocks.BLOCKSTATES, Blocks.AIR.defaultBlockState, palette, data, bitsPerEntry, 4);

							// TODO: Awful
							// Get max y
							if (bitsPerEntry != 0) {
								int x = 0;
								int y = 0;
								int z = 0;
								int count = 0;
								uint64 dataBitmask = GenerateBitMask(bitsPerEntry);

								for (int j < dataSize) {
								    uint64 l = data[j];
								    int entries = 64 / bitsPerEntry;
								    bool end = false;

								    for (int k < entries) {
								        int32 blockIndex = (.) ((l >> k * bitsPerEntry) & dataBitmask);

								        BlockState blockState = Blocks.BLOCKSTATES[palette[blockIndex]];
								        if (blockState == null) blockState = Blocks.AIR.defaultBlockState;

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
						}
						else {
							packet.Skip(dataSize * 8);
							delete palette;
						}
					}
				}
				{
					// Biomes
					int bitsPerEntry = packet.ReadUByte();
					int32[] palette = ReadPalette(packet, bitsPerEntry, 3);
					int dataSize = packet.ReadVarInt();

					if (palette == null) packet.Skip(dataSize * 8);
					else {
						uint64[] data = new .[dataSize];
						for (int j < dataSize) data[j] = (.) packet.ReadLong();

						section.biomes = new .(Biomes.BIOMES, Biomes.VOID, palette, data, bitsPerEntry, 2);
					}
				}
			}

			min.y = minY - 1;
			max.y = maxY + 1;

			dirty = true;
		}

		private static int32[] ReadPalette(NetBuffer packet, int bitsPerEntry, int maxIndirect) {
			int32[] palette = null;

			if (bitsPerEntry == 0) {
				// Single entry
				palette = new int32[1] (packet.ReadVarInt());
			}
			else if (bitsPerEntry <= maxIndirect) {
				// Indirect
				int paletteSize = packet.ReadVarInt();
				palette = new int32[paletteSize];

				for (int j < paletteSize) palette[j] = packet.ReadVarInt();
			}
			else {
				// Direct
				Log.Error("No idea what to do here");
			}

			return palette;
		}

		private static uint64 GenerateBitMask(int bits) {
		    uint64 bitmask = 0;

		    for (int i < bits) {
		        bitmask |= 1 << i;
		    }

		    return bitmask;
		}
	}
}