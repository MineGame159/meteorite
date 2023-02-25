using System;

namespace Meteorite;

class TimeUpdateS2CPacket : S2CPacket {
	public const int32 ID = 0x5A;

	public int64 worldAge, timeOfDay;

	public this() : base(ID, .World) {}

	public override void Read(NetBuffer buf) {
		worldAge = buf.ReadLong();
		timeOfDay = buf.ReadLong();

		if (timeOfDay < 0) timeOfDay = -timeOfDay;
	}
}