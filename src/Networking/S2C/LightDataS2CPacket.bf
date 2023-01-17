using System;

namespace Meteorite;

class LightDataS2CPacket : S2CPacket {
	public const int32 ID = 0x23;

	public ChunkPos pos;
	public LightPacketData data ~ delete _;

	public this() : base(ID, .World) {}

	public override void Read(NetBuffer buf) {
		pos = .(buf.ReadVarInt(), buf.ReadVarInt());
		data = .Read(buf, true);
	}
}

class LightPacketData {
	public bool trustEdges;
	
	public LightBitSet skyLightMask;
	public LightBitSet blockLightMask;
	public LightBitSet emptySkyLightMask;
	public LightBitSet emptyBlockLightMask;
	
	public uint8*[] skyLightSections;
	public uint8*[] blockLightSections;

	private bool ownsSectionData;

	public this(bool trustEdges, LightBitSet skyLightMask, LightBitSet blockLightMask, LightBitSet emptySkyLightMask, LightBitSet emptyBlockLightMask, uint8*[] skyLightSections, uint8*[] blockLightSections, bool ownsSectionData) {
		this.trustEdges = trustEdges;

		this.skyLightMask = skyLightMask;
		this.blockLightMask = blockLightMask;
		this.emptySkyLightMask = emptySkyLightMask;
		this.emptyBlockLightMask = emptyBlockLightMask;

		this.skyLightSections = skyLightSections;
		this.blockLightSections = blockLightSections;

		this.ownsSectionData = ownsSectionData;
	}
	
	public ~this() {
		skyLightMask.Dispose();
		blockLightMask.Dispose();
		emptySkyLightMask.Dispose();
		emptyBlockLightMask.Dispose();

		if (ownsSectionData) {
			for (uint8* section in skyLightSections) delete section;
			for (uint8* section in blockLightSections) delete section;
		}

		delete skyLightSections;
		delete blockLightSections;
	}
	
	public static Self Read(NetBuffer buf, bool copySectionData) {
		bool trustEdges = buf.ReadBool(); // No idea what it is
	
		LightBitSet skyLightMask = .Read(buf);
		LightBitSet blockLightMask = .Read(buf);
		LightBitSet emptySkyLightMask = .Read(buf);
		LightBitSet emptyBlockLightMask = .Read(buf);
	
		int skyLightSectionCount = buf.ReadVarInt();
		uint8*[] skyLightSections = new .[skyLightSectionCount];
	
		for (int i < skyLightSectionCount) {
			int length = buf.ReadVarInt();
			Runtime.Assert(length == 2048);

			if (copySectionData) {
				skyLightSections[i] = new .[length]*;
				Internal.MemCpy(skyLightSections[i], buf.Read(length), length);
			}
			else {
				skyLightSections[i] = buf.Read(length);
			}
		}
	
		int blockLightSectionCount = buf.ReadVarInt();
		uint8*[] blockLightSections = new .[blockLightSectionCount];
	
		for (int i < blockLightSectionCount) {
			int length = buf.ReadVarInt();
			Runtime.Assert(length == 2048);

			if (copySectionData) {
				blockLightSections[i] = new .[length]*;
				Internal.MemCpy(blockLightSections[i], buf.Read(length), length);
			}
			else {
				blockLightSections[i] = buf.Read(length);
			}
		}
	
		return new .(trustEdges, skyLightMask, blockLightMask, emptySkyLightMask, emptyBlockLightMask, skyLightSections, blockLightSections, copySectionData);
	}
}

struct LightBitSet : this(int64[] data), IDisposable {
	public bool IsSet(int bit) {
		int index = bit / 64;
		if (index >= data.Count) return false;

		return (data[index] & (1L << (bit % 64))) != 0;
	}

	public void Dispose() {
		delete data;
	}

	public static Self Read(NetBuffer buf) {
		int length = buf.ReadVarInt();
		int64[] data = new .[length];

		for (int i < length) {
			data[i] = buf.ReadLong();
		}

		return .(data);
	}
}