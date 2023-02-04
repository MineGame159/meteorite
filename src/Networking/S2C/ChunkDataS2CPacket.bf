using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class ChunkDataS2CPacket : S2CPacket {
		public const int32 ID = 0x20;

		public ChunkPos pos;
		public int minY, maxY;

		public Section[] sections;
		public SectionLightData[] sectionLightDatas;

		public Dictionary<Vec3i, BlockEntity> blockEntities;

		private bool consumed;

		public this() : base(ID, .World) {}

		public ~this() {
			if (!consumed) {
				DeleteContainerAndItems!(sections);
				DeleteContainerAndItems!(sectionLightDatas);

				DeleteDictionaryAndValues!(blockEntities);
			}
		}

		public void Consume() => consumed = true;

		public override void Read(NetBuffer buf) {
			pos = .(buf.ReadInt(), buf.ReadInt());

			buf.ReadNbt().Dispose(); // Heightmaps

			// Sections
			int size = buf.ReadVarInt(); // Size
			int afterDataPos = buf.pos + size;

			sections = new .[me.world.SectionCount];
			minY = sections.Count * Section.SIZE;
			maxY = 0;

			for (int i < sections.Count) {
				Section section = sections[i];
				if (section == null) {
					section = new .(i);
					sections[i] = section;
				}
				
				buf.ReadShort(); // Block Count

				{
					// Block states
					uint8 bitsPerEntry = buf.ReadUByte();
					IPalette<BlockState> palette = ReadPalette(buf, bitsPerEntry, 8, Blocks.BLOCKSTATES);

					int dataSize = buf.ReadVarInt();
					IBitStorage storage = ReadStorage(buf, bitsPerEntry, dataSize);

					section.blocks = new .(palette, storage, 4);

					for (int x < Section.SIZE) {
						for (int y < Section.SIZE) {
							for (int z < Section.SIZE) {
								BlockState blockState = section.Get(x, y, z);

								if (blockState.block != Blocks.AIR) {
								    int by = i * Section.SIZE + y;

								    if (by < minY) minY = by;
								    if (by > maxY) maxY = by;
								}
							}
						}
					}
				}

				{
					// Biomes
					uint8 bitsPerEntry = buf.ReadUByte();
					IPalette<Biome> palette = ReadPalette(buf, bitsPerEntry, 3, Biomes.BIOMES);

					int dataSize = buf.ReadVarInt();
					IBitStorage storage = ReadStorage(buf, bitsPerEntry, dataSize);

					section.biomes = new .(palette, storage, 2);
				}
			}

			buf.pos = afterDataPos;

			minY--;
			maxY++;

			// Block Entities
			int32 count = buf.ReadVarInt();
			if (count > 0) {
				blockEntities = new .(count);

				for (int i < count) {
					int8 packedXZ = buf.ReadByte();
					int x = (packedXZ >> 4) & 15;
					int z = packedXZ & 15;

					int y = buf.ReadShort() - me.world.dimension.minY;
																				
					int32 typeId = buf.ReadVarInt();
					Result<Tag> tag = buf.ReadNbt();

					if (typeId >= 0 && typeId < BlockEntityTypes.TYPES.Count) {
						BlockEntity blockEntity = BlockEntityTypes.TYPES[typeId].Create(.(this.pos.x * Section.SIZE + x, y, this.pos.z * Section.SIZE + z));

						if (blockEntity != null) {
							if (tag case .Ok) blockEntity.Load(tag);
	
							blockEntities[.(x, y, z)] = blockEntity;
						}
					}
					else {
						Log.Warning("Received ChunkDataS2CPacket with an invalid Block Entity type ID {}", typeId);
					}

					tag.Dispose();
				}
			}

			// Light
			LightPacketData lightData = .Read(buf, false);
			sectionLightDatas = new .[me.world.SectionCount + 2];

			int skyLightSectionI = 0;
			int blockLightSectionI = 0;

			for (int i < sectionLightDatas.Count) {
				bool hasSkyLight = lightData.skyLightMask.IsSet(i);
				bool hasBlockLight = lightData.blockLightMask.IsSet(i);

				sectionLightDatas[i] = new .(
					hasSkyLight ? lightData.skyLightSections[skyLightSectionI++] : null,
					hasBlockLight ? lightData.blockLightSections[blockLightSectionI++] : null
				);
			}

			delete lightData;
		}

		private static IPalette<T> ReadPalette<T>(NetBuffer buf, int bitsPerEntry, int maxIndirect, T[] global) where T : IID {
			if (bitsPerEntry <= maxIndirect) {
				List<int32> list;

				if (bitsPerEntry == 0) {
					list = new .(1);
					list.Add(buf.ReadVarInt());
				}
				else {
					int count = buf.ReadVarInt();
					list = new .(count);

					for (int i < count) list.Add(buf.ReadVarInt());
				}

				return new IndirectPalette<T>(global, list);
			}

			return new DirectPalette<T>(global);
		}

		private static IBitStorage ReadStorage(NetBuffer buf, int bitsPerEntry, int dataSize) {
			IBitStorage storage;

			if (bitsPerEntry == 0 || dataSize == 0) {
				storage = new SingleBitStorage(0);
			}
			else {
				uint64[] data = new .[dataSize];
				for (int j < dataSize) data[j] = (.) buf.ReadLong();

				storage = new BitStorage(data, bitsPerEntry);
			}

			return storage;
		}
	}
}