using System;
using System.Collections;

namespace Meteorite {
	class ClientPlayerEntity : LivingEntity {
		public Gamemode gamemode;
		public PlayerAbilities abilities ~ delete _;

		public BlockHitResult selection ~ delete _;

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

		public void Turn(Vec2f vec) {
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

		public override void Tick() {
			base.Tick();

			// Block Selection
			Camera camera = Meteorite.INSTANCE.camera;
			Vec3d pos = .(camera.pos.x, camera.pos.y, camera.pos.z);
			Vec3f dir = -camera.GetDirection(true);

			let result = Meteorite.INSTANCE.world.Raycast(pos, pos + .(dir.x, dir.y, dir.z) * 6);

			if (selection != null) delete selection;
			selection = result;
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

		private Vec3d Collide(Vec3d _vec) {
			Vec3d vec = _vec;

			/*Vec3d playerMin = this.pos + vec;
			Vec3d playerMax = this.pos + vec + .(type.width, type.height, type.width);

			mixin Calc() {
				playerMin = this.pos + vec;
				playerMax = this.pos + vec + .(type.width, type.height, type.width);
			}

			mixin Between(double value, double min, double max) {
				value >= min && value <= max
			}

			Meteorite.INSTANCE.world.GetPossibleCollisions(GetAABB().Expand(vec), scope [&](pos, shape) => {
				for (let aabb in shape.[Friend]boxes) {
					Vec3d shapeMin = pos + aabb.min;
					Vec3d shapeMax = pos + aabb.max;

					bool x = Between!(playerMin.x, shapeMin.x, shapeMax.x) || Between!(playerMax.x, shapeMin.x, shapeMax.x);
					bool y = Between!(playerMin.y, shapeMin.y, shapeMax.y) || Between!(playerMax.y, shapeMin.y, shapeMax.y);
					bool z = Between!(playerMin.z, shapeMin.z, shapeMax.z) || Between!(playerMax.z, shapeMin.z, shapeMax.z);

					if (Between!(playerMin.x, shapeMin.x, shapeMax.x) && y && z && vec.x < 0 && playerMin.x <= shapeMax.x) vec.x = vec.x + (shapeMax.x - playerMin.x); Calc!();
					if (Between!(playerMax.x, shapeMin.x, shapeMax.x) && y && z && vec.x > 0 && playerMax.x >= shapeMin.x) vec.x = vec.x - (playerMax.x - shapeMin.x); Calc!();

					if (Between!(playerMin.y, shapeMin.y, shapeMax.y) && x && z && vec.y < 0 && playerMin.y <= shapeMax.y) vec.y = vec.y + (shapeMax.y - playerMin.y); Calc!();
					if (Between!(playerMax.y, shapeMin.y, shapeMax.y) && x && z && vec.y > 0 && playerMax.y >= shapeMin.y) vec.y = vec.y - (playerMax.y - shapeMin.y); Calc!();

					if (Between!(playerMin.z, shapeMin.z, shapeMax.z) && x && y && vec.z < 0 && playerMin.z <= shapeMax.z) vec.z = vec.z + (shapeMax.z - playerMin.z); Calc!();
					if (Between!(playerMax.z, shapeMin.z, shapeMax.z) && x && y && vec.z > 0 && playerMax.z >= shapeMin.z) vec.z = vec.z - (playerMax.z - shapeMin.z); Calc!();
				}
			});*/

			//if (vec.y != 0) Log.Info("{}", vec.y);

			/*Vec3d playerMin = pos + vec;
			Vec3d playerMax = pos + vec + .(type.width, type.height, type.width);

			Meteorite.INSTANCE.world.GetPossibleCollisions(GetAABB().Expand(vec), scope [&](shapePos, shape) => {
				Vec3d shapeMin = shapePos + shape.min;
				Vec3d shapeMax = shapePos + shape.max;

				if (!(playerMax.x <= shapeMin.x || playerMax.z <= shapeMin.z || playerMin.x >= shapeMax.x || playerMin.z >= shapeMax.z)) {
					if (vec.y > 0 && playerMax.y >= shapeMin.y && pos.y <= shapeMin.y) vec.y = shapeMin.y - (pos.y + type.height);
					else if (vec.y < 0 && playerMin.y <= shapeMax.y && pos.y >= shapeMax.y) vec.y = shapeMax.y - pos.y;
				}

				/*if (!(playerMax.x <= shapeMin.x || playerMax.y <= shapeMin.y || playerMin.x >= shapeMax.x || playerMin.y >= shapeMax.y)) {
					if (vec.z > 0 && playerMax.z >= shapeMin.z && pos.z <= shapeMin.z) vec.z = shapeMin.z - (pos.z + type.width);
					else if (vec.z < 0 && playerMin.z <= shapeMax.z && pos.z >= shapeMax.z) vec.z = shapeMax.z - pos.z;
				}

				if (!(playerMax.z <= shapeMin.z || playerMax.y <= shapeMin.y || playerMin.z >= shapeMax.z || playerMin.y >= shapeMax.y)) {
					if (vec.x > 0 && playerMax.x >= shapeMin.x && pos.x <= shapeMin.x) vec.x = shapeMin.x - (pos.x + type.width);
					else if (vec.x < 0 && playerMin.x <= shapeMax.x && pos.x >= shapeMax.x) vec.x = shapeMax.x - pos.x;
				}
				*/
				playerMin = pos + vec;
				playerMax = pos + vec + .(type.width, type.height, type.width);
			});*/
			
			return vec;
		}

		// TODO: Only implemented Self movement type
		public void Move(Vec3d pos) {
			if (noPhysics) {
				this.pos += pos;
				return;
			}

			Vec3d vec = Collide(pos);

			double d = vec.LengthSquared;
			if (d > 1.0E-7) {
				this.pos += vec;
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