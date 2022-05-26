using System;

namespace Meteorite {
	class LoginSuccessS2CPacket : S2CPacket {
		public const int32 ID = 0x02;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {}
	}
}