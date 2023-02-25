using System;
using System.IO;
using System.Collections;

using Cacti;

namespace Meteorite;

class ClientConnection : Connection {
	private PacketHandler handler ~ DeleteAndNullify!(_);

	private append String hostname = .();

	public this(StringView ip, int32 port, StringView hostname) : base(ip, port) {
		this.handler = new LoginPacketHandler(this);
		this.hostname.Set(hostname);
	}

	public void SetHandler(PacketHandler handler) {
		delete this.handler;
		this.handler = handler;
	}

	protected override void OnReady() {
		Send(scope HandshakeC2SPacket(hostname, (.) port));
		Send(scope LoginStartC2SPacket(Meteorite.INSTANCE.accounts.active));
	}

	protected override void OnConnectionLost() {
		handler?.OnConnectionLost();
	}
	
	[Tracy.Profile(variable = true)]
	protected override void OnPacket(int id, NetBuffer packet) {
		__tracy_zone.AddText(id.ToString(.. scope .()));
		
		S2CPacket p = handler?.GetPacket((.) id);

		if (p != null) {
			p.Read(packet);

			if (handler != null) handler.Handle(p);
			else delete p;
		}
	}
	
	[Tracy.Profile]
	public void Send(C2SPacket packet) {
		int size = NetBuffer.GetVarIntSize(packet.id) + packet.DefaultBufferSize;
		NetBuffer buf;

		if (size <= 128) buf = scope:: .(size);
		else {
			buf = new .(size);
			defer:: delete buf;
		}

		buf.WriteVarInt(packet.id);
		packet.Write(buf);

		Send(buf);
	}
}