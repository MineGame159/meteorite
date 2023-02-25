using System;

namespace Meteorite;

class PlayerAbilities {
	public bool invulnerable;
	public bool flying, canFly;
	public bool instaBuild, canBuild;
	public float flyingSpeed, walkingSpeed;

	public void Read(NetBuffer buf) {
		int8 b = buf.ReadByte();
		invulnerable = (b & 1) != 0;
		flying = (b & 2) != 0;
		canFly = (b & 4) != 0;
		instaBuild = (b & 8) != 0;
		flyingSpeed = buf.ReadFloat();
		walkingSpeed = buf.ReadFloat();
	}
}