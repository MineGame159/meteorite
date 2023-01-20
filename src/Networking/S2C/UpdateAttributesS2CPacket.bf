using System;

namespace Meteorite;

class UpdateAttributesS2CPacket : S2CPacket {
	public const int32 ID = 0x66;

	public int entityId;
	public EntityAttribute[] attributes;

	private bool consumed;

	public this() : base(ID, .World) {}

	public ~this() {
		if (!consumed) {
			for (EntityAttribute attribute in attributes) delete attribute;
		}

		delete attributes;
	}

	public void Consume() => consumed = true;

	public override void Read(NetBuffer buf) {
		entityId = buf.ReadVarInt();
		attributes = new .[buf.ReadVarInt()];

		for (ref EntityAttribute attribute in ref attributes) {
			attribute = new .(buf.ReadString(), buf.ReadDouble());

			int modifiers = buf.ReadVarInt();
			for (int i < modifiers) {
				buf.Skip(16); // UUID
				double amount = buf.ReadDouble();
				EntityModifierOperation operation = (.) buf.ReadByte();
				
				attribute.modifiers.Add(.(operation, amount));
			}
		}
	}
}