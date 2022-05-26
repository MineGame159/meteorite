using System;

namespace Meteorite {
	class ClientPlayerEntity : LivingEntity {
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

			SetInput(new PlayerKeyboardInput());
		}

		public void SetInput(PlayerInput input) {
			if (this.input != null) delete this.input;
			this.input = input;
		}

		public void Turn(Vec2 vec) {
			yaw += vec.x / 7;
			pitch -= vec.y / 7;
			pitch = Math.Clamp(pitch, -89.5f, 89.5f);
		}

		protected override void TickMovement() {
			base.TickMovement();

			if (gamemode == .Spectator) {
				int i = 0;
				if (input.IsSneak()) i--;
				if (input.IsJump()) i++;
	
				if (i != 0) {
					deltaMovement += .(0, i * abilities.flyingSpeed * 3, 0);
				}
			}

			Move();
			SendMovement();
		}

		private float GetFrictionInfluencedSpeed(float f) {
			// TODO: On ground, idk if abilities.walkingSpeed is correct here
			return false ? abilities.walkingSpeed * (0.21600002F / (f * f * f)) : (abilities.flyingSpeed * (input.IsSprint() ? 2 : 1));
		}

		public bool OnClimbable() {
			if (gamemode == .Spectator) {
				return false;
			}
			
			// TODO
			return false;
		}

		private Vec3d HandleOnClimbable(Vec3d vec3) {
			// TODO
			if (OnClimbable()) {}

			return vec3;
		}

		private static Vec3d GetInputVector(Vec3d relative, float motionScaler, float facing) {
			double d = relative.LengthSquared;
			if (d < 1.0E-7) return .();

			Vec3d vec3 = (d > 1.0 ? relative.Normalize() : relative) * (motionScaler);
			float f = Math.Sin(facing * (Math.PI_f / 180f));
			float g = Math.Cos(facing * (Math.PI_f / 180f));
			return .(vec3.x * g - vec3.z * f, vec3.y, vec3.z * g + vec3.x * f);
		}

		public void MoveRelative(float amount, Vec3d relative) {
			deltaMovement += GetInputVector(relative, amount, yaw); // TODO: Hopefully yaw
		}

		// TODO: Only implemented Self movement type
		public void Move(Vec3d pos) {
			if (noPhysics) {
				this.pos += pos;
				return;
			}

			double d = pos.LengthSquared;
			if (d > 1.0E-7) {
				this.pos += pos;
			}
		}

		private Vec3d HandleRelativeFrictionAndCalculateMovement(Vec3d vec3, float f) {
			MoveRelative(GetFrictionInfluencedSpeed(f), vec3);
			deltaMovement = HandleOnClimbable(deltaMovement);
			Move(deltaMovement);
			Vec3d vec32 = deltaMovement;
			if ((false || input.IsJump()) // TODO: this.horizontalCollision || this.jumping
				&& (OnClimbable())) {
				vec32 = .(vec32.x, 0.2, vec32.z);
			}

			return vec32;
		}

		private void Move() {
			if (gamemode != .Spectator) return;

			Vec3d travelVector = .(input.GetForward() * 0.98, 0, input.GetLeft() * 0.98);



			double deltaY = deltaMovement.y;
			double gravity = 0.08;



			//BlockPos blockPos = this.getBlockPosBelowThatAffectsMyMovement();
			//float p = this.level.getBlockState(blockPos).getBlock().getFriction();
			float friction = 0.91f;
			Vec3d pos = HandleRelativeFrictionAndCalculateMovement(travelVector, 0.6f);
			double y = pos.y - gravity;

			deltaMovement = .(pos.x * friction, y * 0.98, pos.z * friction);


			
			deltaMovement.y = deltaY * 0.6;
		}

		private void SendMovement() {
			sendPositionTimer++;

			bool positionChanged = (pos - lastSentPos).Length > 2.0E-4 || sendPositionTimer >= 20;
			bool rotationChanged = (yaw - lastSentYaw) != 0 || (pitch - lastSentPitch) != 0;

			// TODO: Figure out On Ground property
			if (positionChanged || rotationChanged) {
				Meteorite.INSTANCE.connection.Send(scope PlayerPositionC2SPacket(this, positionChanged, rotationChanged));
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