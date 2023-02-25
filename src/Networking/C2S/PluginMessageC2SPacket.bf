using System;

namespace Meteorite;

class PluginMessageC2SPacket : C2SPacket {
	public const int32 ID = 0x0C;

	public String channel;
	public String data ~ delete _;

	[AllowAppend]
	public this(StringView channel, StringView data) : base(ID) {
		String c = append .(channel);

		this.channel = c;
		this.data = new .(data);
	}

	public override void Write(NetBuffer buf) {
		buf.WriteString(channel);
		buf.Write((.) data.Ptr, data.Length);
	}
}