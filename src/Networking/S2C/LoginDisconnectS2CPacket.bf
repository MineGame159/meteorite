using System;

namespace Meteorite {
	class LoginDisconnectS2CPacket : S2CPacket {
		public const int32 ID = 0x00;

		public String reason = new .() ~ delete _;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			String str = buf.ReadString();
			Json json = JsonParser.ParseString(str);

			TextUtils.ToString(json, reason);

			json.Dispose();
			delete str;
		}
	}
}