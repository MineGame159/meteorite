using System;
using System.Collections;

namespace Meteorite {
	class JoinGameS2CPacket : S2CPacket {
		public const int32 ID = 0x26;

		public int playerId;
		public bool hardcore;
		public Gamemode gamemode, previousGamemode;
		public List<String> worlds ~ DeleteContainerAndItems!(_);
		public Tag dimensionCodec ~ _.Dispose();
		public Tag dimension ~ _.Dispose();

		public this() : base(ID) {}

		public override void Read(NetBuffer packet) {
			playerId = packet.ReadInt();
			hardcore = packet.ReadBool();
			gamemode = (.) packet.ReadUByte();
			previousGamemode = (.) packet.ReadUByte();

			int worldCount = packet.ReadVarInt();
			worlds = new .(worldCount);
			for (int i < worldCount) worlds.Add(packet.ReadString());

			dimensionCodec = packet.ReadNbt();
			dimension = packet.ReadNbt();
		}
	}
}