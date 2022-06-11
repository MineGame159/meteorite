using System;

namespace Meteorite {
	public class LoginPacketHandler : PacketHandler {
		private ClientConnection connection;

		public this(ClientConnection connection) {
			this.connection = connection;
		}

		// Handlers

		private void OnLoginDisconnect(LoginDisconnectS2CPacket packet) {
			Log.Error("Failed to login: {}", packet.reason);
		}

		private void OnLoginSuccess(LoginSuccessS2CPacket packet) {
			connection.SetHandler(new PlayPacketHandler(connection));
		}

		// Base

		public override S2CPacket GetPacket(int32 id) {
			switch (id) {
			case LoginDisconnectS2CPacket.ID: return new LoginDisconnectS2CPacket();
			case LoginSuccessS2CPacket.ID: return new LoginSuccessS2CPacket();
			}

			return null;
		}

		public override void Handle(S2CPacket packet) {
			switch (packet.id) {
			case LoginDisconnectS2CPacket.ID: OnLoginDisconnect((.) packet);
			case LoginSuccessS2CPacket.ID: OnLoginSuccess((.) packet);
			}
		}
	}
}