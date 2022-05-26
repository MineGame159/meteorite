using System;

namespace Meteorite{
	class KeepAliveC2SPacket : C2SPacket {
		public const int32 ID = 0x0F;

		public uint8[8] data;

		[AllowAppend]
		public this(uint8* data) : base(ID) {
			Internal.MemCpy(&this.data, data, 8);
		}

		public override void Write(NetBuffer buf) {
			buf.Write(&data, data.Count);
		}
	}
}