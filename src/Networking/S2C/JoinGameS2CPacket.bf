using System;
using System.Collections;

namespace Meteorite {
	class JoinGameS2CPacket : S2CPacket {
		public const int32 ID = 0x24;

		public int32 playerId;
		public bool hardcore;
		public Gamemode gamemode, previousGamemode;

		public List<String> dimensionNames ~ DeleteContainerAndItems!(_);

		public Tag registryCodec ~ _.Dispose();

		public String dimensionType ~ delete _;
		public String dimensionName ~ delete _;

		public this() : base(ID) {}

		public override void Read(NetBuffer packet) {
			playerId = packet.ReadInt();
			hardcore = packet.ReadBool();
			gamemode = (.) packet.ReadUByte();
			previousGamemode = (.) packet.ReadUByte();

			int dimensionCount = packet.ReadVarInt();
			dimensionNames = new .(dimensionCount);
			for (int i < dimensionCount) dimensionNames.Add(packet.ReadString());

			registryCodec = packet.ReadNbt();

			dimensionType = packet.ReadString();
			dimensionName = packet.ReadString();
		}
	}
}