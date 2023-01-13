using System;

namespace Meteorite {
	class KeepAliveS2CPacket : S2CPacket {
		public const int32 ID = 0x1F;

		public uint8[8] data;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			Internal.MemCpy(&data, buf.Read(data.Count), data.Count);
		}
	}
}