using System;
using System.IO;
using System.Collections;

namespace Meteorite {
	class ClientConnection : Connection {
		private PacketHandler handler ~ DeleteAndNullify!(_);

		public int32 viewDistance;

		public this(StringView address, int32 port, int32 viewDistance) : base(address, port) {
			this.handler = new LoginPacketHandler(this);
			this.viewDistance = viewDistance;
		}

		public void SetHandler(PacketHandler handler) {
			delete this.handler;
			this.handler = handler;
		}

		protected override void OnReady() {
			Send(scope HandshakeC2SPacket(address, (.) port));
			Send(scope LoginStartC2SPacket("Meteorite"));
		}

		protected override void OnConnectionLost() {
			handler?.OnConnectionLost();
		}

		protected override void OnPacket(int id, NetBuffer packet) {
			S2CPacket p = handler?.GetPacket((.) id);

			if (p != null) {
				p.Read(packet);

				if (handler != null) handler.Handle(p);
				else delete packet;
			}
		}

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
}