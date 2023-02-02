using System;

namespace Meteorite {
	class KeepAliveS2CPacket : S2CPacket {
		public const int32 ID = 0x1F;

		public int64 data;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			data = buf.ReadLong();
		}
	}
}