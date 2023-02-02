using System;

namespace Meteorite{
	class KeepAliveC2SPacket : C2SPacket {
		public const int32 ID = 0x11;

		public int64 data;

		[AllowAppend]
		public this(int64 data) : base(ID) {
			this.data = data;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteLong(data);
		}
	}
}