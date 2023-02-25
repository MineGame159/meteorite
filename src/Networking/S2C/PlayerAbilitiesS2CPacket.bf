using System;

namespace Meteorite;

class PlayerAbilitiesS2CPacket : S2CPacket {
	public const int32 ID = 0x30;

	public bool invulnerable;
	public bool flying, canFly;
	public bool instaBuild, canBuild;
	public float flyingSpeed, walkingSpeed;
											
	public this() : base(ID) {}

	public override void Read(NetBuffer buf) {
		int8 b = buf.ReadByte();

		invulnerable = (b & 1) != 0;
		flying = (b & 2) != 0;
		canFly = (b & 4) != 0;
		instaBuild = (b & 8) != 0;

		flyingSpeed = buf.ReadFloat();
		walkingSpeed = buf.ReadFloat(); // TODO: This is actually a FOV modifier but the server uses the same value for walking speed, read attributes for walking speed instead
	}
}