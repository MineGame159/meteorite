using System;

namespace Meteorite {
	public class LoginPacketHandler : PacketHandler {
		private ClientConnection connection;

		public this(ClientConnection connection) {
			this.connection = connection;
		}

		// Handlers

		private void OnLoginSuccess(LoginSuccessS2CPacket packet) {
			connection.SetHandler(new PlayPacketHandler(connection));
		}

		// Base

		public override S2CPacket GetPacket(int32 id) {
			return id == LoginSuccessS2CPacket.ID ? new LoginSuccessS2CPacket() : null;
		}

		public override void Handle(S2CPacket packet) {
			if (packet.id == LoginSuccessS2CPacket.ID) OnLoginSuccess((.) packet);
		}
	}
}