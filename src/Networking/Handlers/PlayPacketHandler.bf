using System;

using Cacti;

namespace Meteorite;

class PlayPacketHandler : PacketHandler {
	private ClientConnection connection;

	private bool firstPlayerInfo = true, firstPlayerPositionAndLook = true;
	private int32 playerId;
	private Gamemode gamemode;
	private PlayerAbilities abilities;
	private int selectedSlot;

	public this(ClientConnection connection) {
		this.connection = connection;
	}

	public override void OnConnectionLost() {
		me.Execute(new () => {
			DisconnectS2CPacket packet = scope .();
			packet.reason = .Of("Connection lost");

			OnDisconnect(packet);
		});
	}

	// Handlers

	private void OnKeepAlive(KeepAliveS2CPacket packet) {
		connection.Send(scope KeepAliveC2SPacket(packet.data));
	}

	private void OnPlayerInfo(PlayerInfoS2CPacket packet) {
		if (!firstPlayerInfo) return;
		firstPlayerInfo = false;

		connection.Send(scope PluginMessageC2SPacket("minecraft:brand", "meteorite"));
		connection.Send(scope ClientSettingsC2SPacket());
	}

	private void OnJoinGame(JoinGameS2CPacket packet) {
		playerId = packet.playerId;
		gamemode = packet.gamemode;

		if (me.world != null) {
			DeleteAndNullify!(me.worldRenderer);
			DeleteAndNullify!(me.world);

			me.player = null;
		}

		Tag dimensionTypes = packet.registryCodec["minecraft:dimension_type"]["value"];
		DimensionType dimensionType = null;

		for (let tag in dimensionTypes.AsList) {
			if (tag["name"].AsString == packet.dimensionName) {
				dimensionType = new .();
				dimensionType.Read(tag["element"]);

				break;
			}
		}

		Runtime.Assert(dimensionType != null, "Failed to find dimension type");

		me.world = new .(dimensionType);
		me.worldRenderer = new .();

		firstPlayerPositionAndLook = true;

		// Read biomes registry
		if (packet.registryCodec.Contains(BuiltinRegistries.BIOMES.Key.Full)) {
			Registry<Biome> biomes = new .(BuiltinRegistries.BIOMES.Key);

			biomes.Parse(packet.registryCodec[BuiltinRegistries.BIOMES.Key.Full]["value"], scope => Biomes.Parse);

			me.world.registries.Biomes = biomes;
		}
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
			connection.Send(scope ClientStatusC2SPacket(0));

			if (abilities == null) {
				Log.Warning("Player Abilities packet was not received before spawning the player");
				abilities = new .();
			}

			me.world.AddEntity(new ClientPlayerEntity(playerId, .(), 0, 0, gamemode, abilities));
			me.player.inventory.selectedSlot = selectedSlot;

			firstPlayerPositionAndLook = false;
			abilities = null;
		}

		packet.Apply(me.player);
	}

	private void OnChunkData(ChunkDataS2CPacket packet) {
		Chunk chunk = new .(me.world, packet.pos, packet.sections, packet.sectionLightDatas, packet.blockEntities);

		chunk.min.y = packet.minY;
		chunk.max.y = packet.maxY;

		me.world.AddChunk(chunk);
		packet.Consume();
	}

	private void OnLightData(LightDataS2CPacket packet) {
		using (me.world.LockChunks()) {
			Chunk chunk = me.world.GetChunk(packet.pos.x, packet.pos.z, false);
			if (chunk == null) return;
	
			int skyLightSectionI = 0;
			int blockLightSectionI = 0;
	
			for (int i < chunk.[Friend]sectionLightDatas.Count) {
				SectionLightData section = chunk.[Friend]sectionLightDatas[i];
	
				if (packet.data.emptySkyLightMask.IsSet(i)) section.Clear(.Sky);
				else if (packet.data.skyLightMask.IsSet(i)) section.Set(.Sky, packet.data.skyLightSections[skyLightSectionI++]);
				
				if (packet.data.emptyBlockLightMask.IsSet(i)) section.Clear(.Block);
				else if (packet.data.blockLightMask.IsSet(i)) section.Set(.Block, packet.data.blockLightSections[blockLightSectionI++]);
			}
		}
	}

	private void OnBlockChange(BlockChangeS2CPacket packet) {
		me.world.SetBlock(packet.pos.x, packet.pos.y, packet.pos.z, packet.blockState);
	}

	private void OnMultiBlockChange(MultiBlockChangeS2CPacket packet) {
		using (me.world.LockChunks()) {
			Chunk chunk = me.world.GetChunk(packet.sectionPos.x, packet.sectionPos.z, false);
			if (chunk == null) return;
	
			Section section = chunk.GetSection(packet.sectionPos.y);
	
			for (let block in packet.blocks) {
				section.Set(block.pos.x, block.pos.y, block.pos.z, block.blockState);
			}
		}
	}

	private void OnBlockEntityData(BlockEntityDataS2CPacket packet) {
		if (packet.remove) me.world.RemoveBlockEntity(packet.pos.x, packet.pos.y, packet.pos.z);

		BlockEntity blockEntity = me.world.GetBlockEntity(packet.pos.x, packet.pos.y, packet.pos.z);
		if (blockEntity != null && blockEntity.type == packet.type) blockEntity.Load(packet.data);
	}

	private void OnSpawnEntity(SpawnEntityS2CPacket packet) {
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

	private void OnSystemChatMessage(SystemChatMessageS2CPacket packet) {
		if (!packet.actionBar) {
			me.hud.chat.AddMessage(packet.text);
		}
	}

	private void OnPlayerChatMessage(PlayerCharMessageS2CPacket packet) {
		me.hud.chat.AddMessage(packet.text);
	}

	private void OnUpdateAttributes(UpdateAttributesS2CPacket packet) {
		Entity entity = me.world.GetEntity(packet.entityId);
		if (entity != me.player) return;

		me.player.SetAttributes(packet.attributes);
		packet.Consume();
	}

	private void OnSetContainerItems(SetContainerItemsS2CPacket packet) {
		if (packet.windowId != 0) return;

		int i = 0;
		
		for (ItemStack itemStack in packet.items) {
			ItemStack inventoryItemStack = me.player.inventory.items[i];

			if (itemStack == null) inventoryItemStack.Clear();
			else itemStack?.TransferTo(inventoryItemStack);

			i++;
		}
	}

	private void OnSetContainerItem(SetContainerItemS2CPacket packet) {
		if (packet.windowId != 0) return;
		
		ItemStack inventoryItemStack = me.player.inventory.items[packet.slot];

		if (packet.itemStack == null) inventoryItemStack.Clear();
		else packet.itemStack.TransferTo(inventoryItemStack);
	}

	private void OnSetSelectedSlot(SetSelectedSlotS2CPacket packet) {
		if (me.player == null) selectedSlot = packet.slot;
		else me.player.inventory.selectedSlot = packet.slot;
	}

	private void OnSetHealthAndFood(SetHealthAndFoodS2CPacket packet) {
		me.player.health = packet.health;

		me.player.food = packet.food;
		me.player.foodSaturation = packet.foodSaturation;
	}

	private void OnSetXP(SetXPS2CPacket packet) {
		me.player.xpTotal = packet.xpTotal;
		me.player.xpLevel = packet.xpLevel;
		me.player.xpProgress = packet.xpProgress;
	}

	private void OnDisconnect(DisconnectS2CPacket packet) {
		me.Disconnect(packet.reason);
	}

	// Base

	public override S2CPacket GetPacket(int32 id) => Impl.GetPacket(id);

	public override void Handle(S2CPacket packet) {
		if (packet.synchronised) me.Execute(new PacketTask(this, packet));
		else Impl.Dispatch(this, packet);
	}

	class PacketTask : this(PlayPacketHandler handler, S2CPacket packet), ITask {
		private bool ran;

		public ~this() {
			if (!ran) {
				delete packet;
			}
		}

		public void Run() {
			Impl.Dispatch(handler, packet);
			ran = true;
		}
	}

	[PacketHandlerImpl]
	static class Impl {}
}