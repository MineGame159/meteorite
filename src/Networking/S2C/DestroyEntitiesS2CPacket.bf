using System;
using System.Collections;

namespace Meteorite;

class DestroyEntitiesS2CPacket : S2CPacket {
	public const int32 ID = 0x3A;

	public List<int> entityIds ~ delete _;

	public this() : base(ID, .World) {}

	public override void Read(NetBuffer buf) {
		int count = buf.ReadVarInt();
		entityIds = new .(count);

		for (int i < count) entityIds.Add(buf.ReadVarInt());
	}
}