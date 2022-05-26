using System;

namespace Meteorite {
	class PlayerInfoS2CPacket : S2CPacket {
		public const int32 ID = 0x36;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			// TODO
		}
	}
}