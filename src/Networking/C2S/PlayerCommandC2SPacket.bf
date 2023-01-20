using System;

namespace Meteorite;

enum PlayerCommand {
	StartSneaking,
	StopSneaking,
	LeaveBed,
	StartSprinting,
	StopSprinting,
	StartJumpWithHorse,
	StopJumpWithHorse,
	OpenHorseInventory,
	StartFlyingWithElytra
}

class PlayerCommandC2SPacket : C2SPacket {
	public const int32 ID = 0x1D;

	public int32 entityId;
	public int32 commandId;

	public this(Entity entity, PlayerCommand command) : base(ID) {
		entityId = entity.id;
		commandId = (.) command;
	}

	public override void Write(NetBuffer buf) {
		buf.WriteVarInt(entityId);
		buf.WriteVarInt(commandId);
		buf.WriteVarInt(0); // Horse jump boost
	}
}