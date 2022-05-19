using System;
using System.IO;

namespace Meteorite {
	class ClientConnection : Connection {
		private const int32 C2S_HANDSHAKE = 0x00;
		private const int32 C2S_LOGIN_START = 0x00;

		private const int32 S2C_LOGIN_SUCCESS = 0x02;

		private const int32 S2C_KEEP_ALIVE = 0x21;
		private const int32 C2S_KEEP_ALIVE = 0x0F;

		private const int32 S2C_JOIN_GAME = 0x26;
		private const int32 S2C_PLAYER_INFO = 0x36;
		private const int32 S2C_PLAYER_POSITION_AND_LOOK = 0x38;
		private const int32 S2C_CHUNK_DATA_AND_UPDATE_LIGHT = 0x22;
		private const int32 S2C_CHAT_MESSAGE = 0x0F;
		private const int32 S2C_SPAWN_ENTITY = 0x00;
		private const int32 S2C_SPAWN_LIVING_ENTITY = 0x02;
		private const int32 S2C_DESTROY_ENTITIES = 0x3A;
		private const int32 S2C_ENTITY_POSITION = 0x29;
		private const int32 S2C_ENTITY_POSITION_AND_ROTATION = 0x2A;
		private const int32 S2C_ENTITY_ROTATION = 0x2B;
		private const int32 S2C_ENTITY_TELEPORT = 0x62;
		private const int32 S2C_TIME_UPDATE = 0x59;

		private const int32 C2S_PLUGIN_MESSAGE = 0x0A;
		private const int32 C2S_CLIENT_SETTINGS = 0x05;
		private const int32 C2S_TELEPORT_CONFIRM = 0x00;
		private const int32 C2S_CLIENT_STATUS = 0x04;

		private Meteorite me;
		private int32 viewDistance;

		private bool playState, firstPlayerInfo = true, firstPlayerPositionAndLook = true;

		public this(StringView address, int32 port, int32 viewDistance) : base(address, port) {
			this.me = Meteorite.INSTANCE;
			this.viewDistance = viewDistance;
		}

		protected override void OnReady() {
			{
				// Handshake
				NetBuffer buf = scope .();
				buf.WriteVarInt(C2S_HANDSHAKE); // ID
				buf.WriteVarInt(758); // Protocol version (1.18.1)
				buf.WriteString(address); // Address
				buf.WriteUShort((.) port); // Port
				buf.WriteVarInt(2); // Next state

				Send(buf);
			}

			{
				// Login start
				NetBuffer buf = scope .();
				buf.WriteVarInt(C2S_LOGIN_START); // ID
				buf.WriteString("Meteorite"); // Username

				Send(buf);
			}
		}

		protected override void OnPacket(int id, NetBuffer packet) {
			if (!playState) {
				if (id == S2C_LOGIN_SUCCESS) {
					playState = true;
					return;
				}

				return;
			}

			switch (id) {
			case S2C_KEEP_ALIVE:
				NetBuffer buf = scope .();
				buf.WriteVarInt(C2S_KEEP_ALIVE); // ID
				buf.Write(packet.Read(8), 8); // Keep alive ID (?????????????? long hello?)

				Send(buf);
			case S2C_JOIN_GAME:
				packet.Skip(4 + 1 + 1 + 1); // Entity ID, Hardcode, Gamemode, Previous Gamemode
				int worldCount = packet.ReadVarInt();
				for (int i < worldCount) delete packet.ReadString();
				Tag dimensionCodec = packet.ReadNbt();
				Tag dimension = packet.ReadNbt();

				int minY = dimension["min_y"].AsInt;
				int height = dimension["height"].AsInt;

				if (me.world != null) delete me.world;
				me.world = new .(viewDistance, minY, height);

				dimension.Dispose();
				dimensionCodec.Dispose();
			case S2C_PLAYER_INFO:
				if (!firstPlayerInfo) break;
				firstPlayerInfo = false;

				{
				    // Plugin Message
				    NetBuffer buf = scope .();
				    buf.WriteVarInt(C2S_PLUGIN_MESSAGE); // ID
				    buf.WriteString("minecraft:brand"); // Channel
				    buf.Write((uint8*) "meteorite", 7); // Data

				    Send(buf);
				}
				{
				    // Client Settings
				    NetBuffer buf = scope .();
				    buf.WriteVarInt(C2S_CLIENT_SETTINGS); // ID
				    buf.WriteString("en_GB"); // Locale
				    buf.WriteByte((.) viewDistance); // View Distance
				    buf.WriteVarInt(0); // Chat Mode (0 - enabled)
				    buf.WriteBool(true); // Chat Colors
				    buf.WriteUByte(0); // Displayed Skin Parts
				    buf.WriteVarInt(1); // Main Hand (0 - left, 1 - right)
					buf.WriteBool(false); // Enable text filtering
					buf.WriteBool(true); // Allow server listings

				    Send(buf);
				}
			case S2C_PLAYER_POSITION_AND_LOOK:
				double x = packet.ReadDouble();
				double y = packet.ReadDouble() - me.world.minY + 2;
				double z = packet.ReadDouble();

				double yaw = packet.ReadFloat();
				double pitch = packet.ReadFloat();

				packet.Skip(1); // Flags
				int32 teleportId = packet.ReadVarInt();

				{
					// Teleport Confirm
					NetBuffer buf = scope .();
					buf.WriteVarInt(C2S_TELEPORT_CONFIRM); // ID
					buf.WriteVarInt(teleportId); // Teleport ID

					Send(buf);
				}

				if (firstPlayerPositionAndLook) {
					Camera c = Meteorite.INSTANCE.camera;
					c.pos = .((.) x, (.) y, (.) z);
					c.yaw = (.) yaw;
					c.pitch = (.) pitch;

					{
						// Client Status
						NetBuffer buf = scope .();
						buf.WriteVarInt(C2S_CLIENT_STATUS); // ID
						buf.WriteVarInt(0); // Action ID (0 - respawn, 1 - stats)

						Send(buf);
					}

					firstPlayerPositionAndLook = false;
				}
			case S2C_CHUNK_DATA_AND_UPDATE_LIGHT:
				if (me.world == null) return;

				int32 x = packet.ReadInt();
				int32 z = packet.ReadInt();

				Chunk chunk = new .(me.world, .(x, z));
				chunk.Load(packet);

				me.world.AddChunk(chunk);
			case S2C_CHAT_MESSAGE:
				String text = packet.ReadString();
				Json json = JsonParser.ParseString(text);
				int8 position = packet.ReadByte();

				// 2 - above hotbar thing
				if (position != 2) {
					text.Clear();
					TextUtils.ToString(json, text);

					Log.Chat(text);
				}

				json.Dispose();
				delete text;
			case S2C_SPAWN_ENTITY, S2C_SPAWN_LIVING_ENTITY:
				if (me.world == null) return;

				int entityId = packet.ReadVarInt();
				packet.Skip(16); // UUID
				EntityType type = EntityTypes.ENTITY_TYPES[packet.ReadVarInt()];
				double x = packet.ReadDouble();
				double y = packet.ReadDouble() - me.world.minY;
				double z = packet.ReadDouble();

				me.world.AddEntity(new .(type, entityId, .(x, y, z)));
			case S2C_DESTROY_ENTITIES:
				if (me.world == null) return;

				int count = packet.ReadVarInt();

				for (int i < count) {
					int entityId = packet.ReadVarInt();
					me.world.RemoveEntity(entityId);
				}
			case S2C_ENTITY_POSITION, S2C_ENTITY_POSITION_AND_ROTATION:
				if (me.world == null) return;

				int entityId = packet.ReadVarInt();
				int16 deltaX = packet.ReadShort();
				int16 deltaY = packet.ReadShort();
				int16 deltaZ = packet.ReadShort();

				Entity entity = me.world.GetEntity(entityId);
				if (entity != null) {
					double x = deltaX == 0 ? entity.trackedPos.x : DecodePacketCoordinate(EncodePacketCoordinate(entity.trackedPos.x) + (int64) deltaX);
					double y = deltaY == 0 ? entity.trackedPos.y : DecodePacketCoordinate(EncodePacketCoordinate(entity.trackedPos.y) + (int64) deltaY);
					double z = deltaZ == 0 ? entity.trackedPos.z : DecodePacketCoordinate(EncodePacketCoordinate(entity.trackedPos.z) + (int64) deltaZ);

					entity.trackedPos = .(x, y, z);
					entity.serverPos = .(x, y, z);
					entity.bodyTrackingIncrements = 3;

					if (id == S2C_ENTITY_POSITION_AND_ROTATION) {
						entity.yaw = packet.ReadAngle();
						entity.pitch = packet.ReadAngle();
					}
				}
			case S2C_ENTITY_ROTATION:
				if (me.world == null) return;

				int entityId = packet.ReadVarInt();

				Entity entity = me.world.GetEntity(entityId);
				if (entity != null) {
					entity.yaw = packet.ReadAngle();
					entity.pitch = packet.ReadAngle();
				}
			case S2C_ENTITY_TELEPORT:
				if (me.world == null) return;

				int entityId = packet.ReadVarInt();
				double x = packet.ReadDouble();
				double y = packet.ReadDouble() - me.world.minY;
				double z = packet.ReadDouble();

				Entity entity = me.world.GetEntity(entityId);
				if (entity != null) {
					entity.trackedPos = .(x, y, z);
					entity.serverPos = .(x, y, z);
					entity.bodyTrackingIncrements = 3;
				}
			case S2C_TIME_UPDATE:
				if (me.world == null) return;

				int64 worldAge = packet.ReadLong();
				int64 timeOfDay = packet.ReadLong();

				if (timeOfDay < 0) timeOfDay = -timeOfDay;

				me.world.worldAge = worldAge;
				me.world.timeOfDay = timeOfDay;
			}
		}

		private static double DecodePacketCoordinate(int64 coord) => coord / 4096.0;
		private static int64 EncodePacketCoordinate(double coord) => Utils.Lfloor(coord * 4096.0);
	}
}