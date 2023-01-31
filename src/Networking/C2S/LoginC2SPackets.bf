using System;

namespace Meteorite {
	class HandshakeC2SPacket : C2SPacket {
		public const int32 ID = 0x00;

		public append String address = .();
		public uint16 port;

		[AllowAppend]
		public this(StringView address, uint16 port) : base(ID) {
			this.address.Set(address);
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

		public Account account;

		[AllowAppend]
		public this(Account account) : base(ID) {
			this.account = account;
		}

		public override void Write(NetBuffer buf) {
			buf.WriteString(account.username);

			bool hasUuid = account.type == .Microsoft;
			buf.WriteBool(hasUuid);

			if (hasUuid) {
				buf.WriteUUID(account.uuid);
			}
		}
	}

	class EncryptionResponseC2SPacket : C2SPacket {
		public const int32 ID = 0x01;

		public uint8[] sharedSecret ~ delete _;
		public uint8[] verifyToken ~ delete _;

		public this(uint8[] sharedSecret, uint8[] verifyToken) : base(ID) {
			this.sharedSecret = new .[sharedSecret.Count];
			this.verifyToken = new .[verifyToken.Count];

			sharedSecret.CopyTo(this.sharedSecret);
			verifyToken.CopyTo(this.verifyToken);
		}

		public override int DefaultBufferSize => (4 * 128) * 2;

		public override void Write(NetBuffer buf) {
			buf.WriteVarInt((.) sharedSecret.Count);
			buf.Write(sharedSecret.Ptr, sharedSecret.Count);

			buf.WriteVarInt((.) verifyToken.Count);
			buf.Write(verifyToken.Ptr, verifyToken.Count);
		}
	}
}