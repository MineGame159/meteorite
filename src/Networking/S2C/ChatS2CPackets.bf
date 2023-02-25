using System;

namespace Meteorite;

class SystemChatMessageS2CPacket : S2CPacket {
	public const int32 ID = 0x60;

	public Text text ~ delete _;
	public bool actionBar;

	public this() : base(ID, .World) {}

	public override void Read(NetBuffer buf) {
		text = buf.ReadText();
		actionBar = buf.ReadBool();
	}
}

class PlayerCharMessageS2CPacket : S2CPacket {
	public const int32 ID = 0x31;

	public Text text ~ delete _;

	public this() : base(ID, .Nothing) {}

	public override void Read(NetBuffer buf) {
		buf.Skip(16); // Sender UUID
		buf.ReadVarInt(); // Index

		bool hasMessageSignature = buf.ReadBool();
		if (hasMessageSignature) buf.Skip(256);

		String contentRaw = buf.ReadString();
		Text content = .Of(contentRaw);
		delete contentRaw;

		buf.Skip(8); // Timestamp
		buf.Skip(8); // Salt

		int totalPreviousMessages = buf.ReadVarInt();
		for (int i < totalPreviousMessages) {
			int id = buf.ReadVarInt();
			if (id != 0) buf.Skip(256);
		}

		bool hasUnsignedContent = buf.ReadBool();
		Text unsignedContent = hasUnsignedContent ? buf.ReadText() : null;

		int filterType = buf.ReadVarInt();
		if (filterType == 2) {
			int count = buf.ReadVarInt();
			for (int i < count) buf.ReadLong();
		}

		//ChatType chatType = ChatTypes.TYPES[buf.ReadVarInt()];
		buf.ReadVarInt();
		Text networkName = buf.ReadText();

		bool hasNetworkTargetName = buf.ReadBool();
		Text networkTargetName = hasNetworkTargetName ? buf.ReadText() : null;

		if (unsignedContent != null) {
			text = unsignedContent;
			delete content;
		}
		else {
			// TODO: Needs to be decorated based on the chat type
			text = content;
		}

		delete networkName;
		delete networkTargetName;
	}
}