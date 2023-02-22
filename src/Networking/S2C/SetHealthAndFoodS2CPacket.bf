using System;

namespace Meteorite;

class SetHealthAndFoodS2CPacket : S2CPacket {
	public const int32 ID = 0x53;

	public float health;

	public int food;
	public float foodSaturation;

	public this() : base(ID, .Player) {}

	public override void Read(NetBuffer buf) {
		health = buf.ReadFloat();

		food = buf.ReadVarInt();
		foodSaturation = buf.ReadFloat();
	}
}