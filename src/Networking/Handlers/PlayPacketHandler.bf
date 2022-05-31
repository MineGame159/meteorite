using System;

namespace Meteorite {
	class PlayPacketHandler : PacketHandler {
		private ClientConnection connection;

		private bool firstPlayerInfo = true, firstPlayerPositionAndLook = true;
		private int playerId;
		private Gamemode gamemode;
		private PlayerAbilities abilities;

		public this(ClientConnection connection) {
			this.connection = connection;
		}

		// Handlers

		private void OnKeepAlive(KeepAliveS2CPacket packet) {
			connection.Send(scope KeepAliveC2SPacket(&packet.data[0]));
		}

		private void OnPlayerInfo(PlayerInfoS2CPacket packet) {
			if (!firstPlayerInfo) return;
			firstPlayerInfo = false;

			connection.Send(scope PluginMessageC2SPacket("minecraft:brand", "meteorite"));
			connection.Send(scope ClientSettingsC2SPacket(connection.viewDistance));
		}

		private void OnJoinGame(JoinGameS2CPacket packet) {
			playerId = packet.playerId;
			gamemode = packet.gamemode;

			if (me.world != null) {
				delete me.world;
				delete me.worldRenderer;
			}

			me.world = new .(connection.viewDistance, packet.dimension["min_y"].AsInt, packet.dimension["height"].AsInt);
			me.worldRenderer = new .();
		}

		private void OnPlayerAbilities(PlayerAbilitiesS2CPacket packet) {
			PlayerAbilities abilities;

			if (me.world == null || me.player == null) {
				if (this.abilities == null) this.abilities = new .();
				abilities = this.abilities;
			}
			else {
				abilities = me.player.abilities;
			}

			abilities.invulnerable = packet.invulnerable;
			abilities.flying = packet.flying;
			abilities.canFly = packet.canFly;
			abilities.instaBuild = packet.instaBuild;
			abilities.canBuild = packet.canBuild;
			abilities.flyingSpeed = packet.flyingSpeed;
			abilities.walkingSpeed = packet.walkingSpeed;
		}

		private void OnPlayerPositionAndLook(PlayerPositionAndLookS2CPacket packet) {
			connection.Send(scope ConfirmTeleportC2SPacket(packet.teleportId));

			if (firstPlayerPositionAndLook) {
				Camera c = me.camera;
				c.pos = .((.) packet.x, (.) packet.y - (2 - 1.62f), (.) packet.z);
				c.yaw = (.) packet.yaw;
				c.pitch = (.) packet.pitch;

				connection.Send(scope ClientStatusC2SPacket(0));

				if (abilities == null) Log.Error("Player Abilities packet was not received before spawning the player");

				me.world.AddEntity(new ClientPlayerEntity(playerId, .(packet.x, packet.y - 2, packet.z), (.) packet.yaw, (.) packet.pitch, gamemode, abilities));

				firstPlayerPositionAndLook = false;
			}
		}

		private void OnChunkData(ChunkDataS2CPacket packet) {
			Chunk chunk = new .(me.world, packet.pos, packet.sections);

			chunk.min.y = packet.minY;
			chunk.max.y = packet.maxY;

			me.world.AddChunk(chunk);
		}

		private void OnSpawnEntity(SpawnEntityS2CPacket packet) {
			me.world.AddEntity(new .(packet.type, packet.entityId, .(packet.x, packet.y, packet.z)));
		}

		private void OnSpawnLivingEntity(SpawnLivingEntityC2SPacket packet) {
			me.world.AddEntity(new .(packet.type, packet.entityId, .(packet.x, packet.y, packet.z)));
		}

		private void OnDestroyEntities(DestroyEntitiesS2CPacket packet) {
			for (let id in packet.entityIds) me.world.RemoveEntity(id);
		}

		private void OnEntityPosition(BaseEntityPositionS2CPacket packet) {
			Entity entity = me.world.GetEntity(packet.entityId);
			if (entity == null) return;

			if (packet.hasPosition) {
				Vec3d pos = packet.GetPos(entity);

				entity.trackedPos = pos;
				entity.serverPos = pos;
				entity.bodyTrackingIncrements = 3;
			}

			if (packet.hasRotation) {
				entity.yaw = packet.yaw;
				entity.pitch = packet.pitch;
			}
		}

		private void OnTimeUpdate(TimeUpdateS2CPacket packet) {
			me.world.worldAge = packet.worldAge;
			me.world.timeOfDay = packet.timeOfDay;
		}

		private void OnChangeGameState(ChangeGameStateS2CPacket packet) {
			if (packet.reason == 3) me.player.gamemode = (.) packet.value;
		}

		private void OnChatMessage(ChatMessageS2CPacket packet) {
			// 2 - above hotbar thing
			if (packet.position != 2) {
				String text = scope .();
				TextUtils.ToString(packet.text, text);

				Log.Chat(text);
			}
		}

		// Base

		public override S2CPacket GetPacket(int32 id) {
			switch (id) {
			case KeepAliveS2CPacket.ID: return new KeepAliveS2CPacket();
			case PlayerInfoS2CPacket.ID: return new PlayerInfoS2CPacket();
			case JoinGameS2CPacket.ID: return new JoinGameS2CPacket();
			case PlayerAbilitiesS2CPacket.ID: return new PlayerAbilitiesS2CPacket();
			case PlayerPositionAndLookS2CPacket.ID: return new PlayerPositionAndLookS2CPacket();
			case ChunkDataS2CPacket.ID: return new ChunkDataS2CPacket();
			case SpawnEntityS2CPacket.ID: return new SpawnEntityS2CPacket();
			case SpawnLivingEntityC2SPacket.ID: return new SpawnLivingEntityC2SPacket();
			case DestroyEntitiesS2CPacket.ID: return new DestroyEntitiesS2CPacket();
			case EntityPositionS2CPacket.ID: return new EntityPositionS2CPacket();
			case EntityRotationS2CPacket.ID: return new EntityRotationS2CPacket();
			case EntityPositionAndRotationS2CPacket.ID: return new EntityPositionAndRotationS2CPacket();
			case EntityTeleportS2CPacket.ID: return new EntityTeleportS2CPacket();
			case TimeUpdateS2CPacket.ID: return new TimeUpdateS2CPacket();
			case ChangeGameStateS2CPacket.ID: return new ChangeGameStateS2CPacket();
			case ChatMessageS2CPacket.ID: return new ChatMessageS2CPacket();
			}

			return null;
		}

		public override void Handle(S2CPacket packet) {
			CheckPacketCondition!(packet);

			switch (packet.id) {
			case KeepAliveS2CPacket.ID: OnKeepAlive((.) packet);
			case PlayerInfoS2CPacket.ID: OnPlayerInfo((.) packet);
			case JoinGameS2CPacket.ID: OnJoinGame((.) packet);
			case PlayerAbilitiesS2CPacket.ID: OnPlayerAbilities((.) packet);
			case PlayerPositionAndLookS2CPacket.ID: OnPlayerPositionAndLook((.) packet);
			case ChunkDataS2CPacket.ID: OnChunkData((.) packet);
			case SpawnEntityS2CPacket.ID: OnSpawnEntity((.) packet);
			case SpawnLivingEntityC2SPacket.ID: OnSpawnLivingEntity((.) packet);
			case DestroyEntitiesS2CPacket.ID: OnDestroyEntities((.) packet);
			case EntityPositionS2CPacket.ID: OnEntityPosition((.) packet);
			case EntityRotationS2CPacket.ID: OnEntityPosition((.) packet);
			case EntityPositionAndRotationS2CPacket.ID: OnEntityPosition((.) packet);
			case EntityTeleportS2CPacket.ID: OnEntityPosition((.) packet);
			case TimeUpdateS2CPacket.ID: OnTimeUpdate((.) packet);
			case ChangeGameStateS2CPacket.ID: OnChangeGameState((.) packet);
			case ChatMessageS2CPacket.ID: OnChatMessage((.) packet);
			}
		}
	}
}