using System;

namespace Meteorite {
	class ChunkDataS2CPacket : S2CPacket {
		public const int32 ID = 0x22;

		public int32 x, z;
		public NetBuffer data ~ delete _;

		public this() : base(ID, .World) {}

		public override void Read(NetBuffer buf) {
			x = buf.ReadInt();
			z = buf.ReadInt();
			
			buf.ReadNbt().Dispose();

			int size = buf.ReadVarInt();
			data = new .(size);
			Internal.MemCpy(data.data, buf.Read(size), size);
		}
	}
}