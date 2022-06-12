using System;

namespace Meteorite {
	abstract class PacketHandler {
		protected Meteorite me = .INSTANCE;

		public abstract void OnConnectionLost();

		public abstract S2CPacket GetPacket(int32 id);

		public abstract void Handle(S2CPacket packet);

		protected mixin CheckPacketCondition(S2CPacket packet) {
			if (packet.requires == .World && me.world == null) return;
			if (packet.requires == .Player && (me.world == null || me.player == null)) return;
		}
	}
}