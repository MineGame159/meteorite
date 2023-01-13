using System;

namespace Meteorite {
	class HandshakeC2SPacket : C2SPacket {
		public const int32 ID = 0x00;

		public String address;
		public uint16 port;

		[AllowAppend]
		public this(StringView address, uint16 port) : base(ID) {
			String a = append .(address);
			this.address = a;
			this.port = port;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteVarInt(761); // Protocol version (1.19.3)
			buf.WriteString(address); // Address
			buf.WriteUShort((.) port); // Port
			buf.WriteVarInt(2); // Next state
		}
	}

	class LoginStartC2SPacket : C2SPacket {
		public const int32 ID = 0x00;

		public String username;

		[AllowAppend]
		public this(StringView username) : base(ID) {
			String u = append .(username);
			this.username = u;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteString(username); // Username
			buf.WriteBool(false); // Has player UUID
			// Player UUID
		}
	}
}