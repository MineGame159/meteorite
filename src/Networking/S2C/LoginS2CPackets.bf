using System;

namespace Meteorite {
	class EncryptionRequestS2CPacket : S2CPacket {
		public const int32 ID = 0x01;

		public String serverId ~ delete _;
		public uint8[] publicKey ~ delete _;
		public uint8[] verifyToken ~ delete _;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {
			serverId = buf.ReadString();

			int publicKeyLength = buf.ReadVarInt();
			publicKey = new .[publicKeyLength];
			Internal.MemCpy(publicKey.Ptr, buf.Read(publicKeyLength), publicKeyLength);

			int verifyTokenLength = buf.ReadVarInt();
			verifyToken = new .[verifyTokenLength];
			Internal.MemCpy(verifyToken.Ptr, buf.Read(verifyTokenLength), verifyTokenLength);
		}
	}

	class LoginSuccessS2CPacket : S2CPacket {
		public const int32 ID = 0x02;

		public this() : base(ID) {}

		public override void Read(NetBuffer buf) {}
	}
}