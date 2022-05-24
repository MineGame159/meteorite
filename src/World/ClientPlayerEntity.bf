using System;

namespace Meteorite {
	class ClientPlayerEntity : Entity {
		public Gamemode gamemode;
		public PlayerAbilities abilities ~ delete _;

		private Vec3d lastSentPos;
		private float lastSentYaw, lastSentPitch;
		private int sendPositionTimer;

		private PlayerInput input ~ delete _;

		public this(int id, Vec3d pos, float yaw, float pitch, Gamemode gamemode, PlayerAbilities abilities) : base(EntityTypes.PLAYER, id, pos) {
			this.gamemode = gamemode;
			this.abilities = abilities;

			this.lastSentPos = pos;
			this.yaw = yaw;
			this.pitch = pitch;
			this.lastSentYaw = yaw;
			this.lastSentPitch = pitch;
		}

		public override void Tick() {
			base.Tick();
			SendMovement();
		}

		private void SendMovement() {
			sendPositionTimer++;

			bool positionChanged = (pos - lastSentPos).Length > 2.0E-4 || sendPositionTimer >= 20;
			bool rotationChanged = (yaw - lastSentYaw) != 0 || (pitch - lastSentPitch) != 0;

			// TODO: Figure out On Ground property

			if (positionChanged && rotationChanged) {
				NetBuffer buf = scope .();
				buf.WriteVarInt(ClientConnection.C2S_PLAYER_POSITION_AND_ROTATION);
				buf.WriteDouble(pos.x);
				buf.WriteDouble(pos.y + Meteorite.INSTANCE.world.minY);
				buf.WriteDouble(pos.z);
				buf.WriteFloat(yaw);
				buf.WriteFloat(pitch);
				buf.WriteBool(false);

				Meteorite.INSTANCE.connection.Send(buf);
			}
			else if (positionChanged) {
				NetBuffer buf = scope .();
				buf.WriteVarInt(ClientConnection.C2S_PLAYER_POSITION);
				buf.WriteDouble(pos.x);
				buf.WriteDouble(pos.y + Meteorite.INSTANCE.world.minY);
				buf.WriteDouble(pos.z);
				buf.WriteBool(false);

				Meteorite.INSTANCE.connection.Send(buf);
			}
			else if (rotationChanged) {
				NetBuffer buf = scope .();
				buf.WriteVarInt(ClientConnection.C2S_PLAYER_ROTATION);
				buf.WriteFloat(yaw);
				buf.WriteFloat(pitch);
				buf.WriteBool(false);

				Meteorite.INSTANCE.connection.Send(buf);
			}

			if (positionChanged) {
				lastSentPos = pos;
				sendPositionTimer = 0;
			}

			if (rotationChanged) {
				lastSentYaw = yaw;
				lastSentPitch = pitch;
			}
		}
	}
}