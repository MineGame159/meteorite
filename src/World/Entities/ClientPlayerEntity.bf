using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class ClientPlayerEntity : LivingEntity {
		public Gamemode gamemode;
		public PlayerAbilities abilities ~ delete _;

		public Inventory inventory = new .() ~ delete _;
		public BlockHitResult selection ~ delete _;

		private Dictionary<StringView, EntityAttribute> attributes = new .() ~ DeleteDictionaryAndValues!(_);

		private Vec3d lastSentPos, prevPos;
		private float lastSentYaw, lastSentPitch;
		private bool lastSentOnGround, lastSentSprinting;
		private int sendPositionTimer;

		private PlayerInput input ~ delete _;
		private Vec3d velocity;
		private double flyingSpeed = 0.02;

		private bool sprinting;
		private int jumpCooldown;
		private int flyToggleCooldown;

		public bool onGround;

		public int food;
		public float foodSaturation;

		public int xpTotal;
		public int xpLevel;
		public float xpProgress;

		public this(int32 id, Vec3d pos, float yaw, float pitch, Gamemode gamemode, PlayerAbilities abilities) : base(EntityTypes.PLAYER, id, pos) {
			this.gamemode = gamemode;
			this.abilities = abilities;

			this.lastSentPos = pos;
			this.prevPos = pos;
			this.yaw = yaw;
			this.pitch = pitch;
			this.lastSentYaw = yaw;
			this.lastSentPitch = pitch;
			this.lastSentOnGround = onGround;

			SetInput(new PlayerKeyboardInput());
		}

		public override float GetMaxHealth() => (.) GetAttribute(EntityAttributes.GENERIC_MAX_HEALTH, 20);

		public void SetInput(PlayerInput input) {
			if (this.input != null) delete this.input;
			this.input = input;
		}

		public void Turn(Vec2f vec) {
			float sensitivity = Meteorite.INSTANCE.options.mouseSensitivity;

			yaw += vec.x / 7 * sensitivity;
			pitch -= vec.y / 7 * sensitivity;

			pitch = Math.Clamp(pitch, -89.5f, 89.5f);
		}

		public double Speed => (pos.XZ - prevPos.XZ).Length * 20;

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

		protected override void TickMovement() {
			prevPos = pos;

			Vec2d prevMovement = input.movement;
			bool prevJump = input.jump;

			input.Tick();

			// Start / stop sprinting if needed
			if ((onGround || abilities.flying) && input.sprint) {
				sprinting = true;
			}
			else if (sprinting && !prevMovement.IsZero && input.movement.IsZero) {
				sprinting = false;
			}

			// Start / stop flying if needed
			if (abilities.canFly) {
				if (gamemode == .Spectator) {
					if (!abilities.flying) {
						abilities.flying = true;
						SendAbilities();
					}
				}
				else {
					if (!prevJump && input.jump) {
						if (flyToggleCooldown == 0) {
							flyToggleCooldown = 7;
						}
						else {
							abilities.flying = !abilities.flying;
							SendAbilities();

							flyToggleCooldown = 0;
						}
					}
				}
			}

			if (flyToggleCooldown > 0) {
				flyToggleCooldown--;
			}

			// Get movement
			Vec2d movement = input.movement;

			// Sneaking
			if (false) {
				movement *= 0.3;
			}

			// Using item
			if (false) {
				movement *= 0.2;
			}
			
			// Flying
			if (jumpCooldown > 0) {
				jumpCooldown--;
			}

			if (abilities.flying) {
				velocity.y += input.vertical * abilities.flyingSpeed * 3;
			}
			// Jumping
			else {
				if (input.jump && onGround && jumpCooldown == 0) {
					velocity.y = 0.42;

					if (!movement.IsZero && sprinting) {
						double yawRad = Math.DEG2RADd * yaw;
						velocity += .(-(Math.Cos(yawRad) * 0.2), 0, -(Math.Sin(yawRad) * 0.2));
					}

					jumpCooldown = 10;
				}
			}

			// Move
			if (Math.Abs(velocity.x) < 0.003) velocity.x = 0;
			if (Math.Abs(velocity.y) < 0.003) velocity.y = 0;
			if (Math.Abs(velocity.z) < 0.003) velocity.z = 0;

			movement *= 0.98;
			
			if (abilities.flying) {
				// Flying
				double prevFlyingSpeed = flyingSpeed;
				flyingSpeed = abilities.flyingSpeed;

				if (sprinting) {
					flyingSpeed *= 2;
				}

				Move(movement);
				velocity.y *= 0.6;

				flyingSpeed = prevFlyingSpeed;
			}
			else {
				// Walking
				Move(movement);
			}

			// Stop flying if touching ground
			if (onGround && abilities.flying && gamemode != .Spectator) {
				abilities.flying = false;
				SendAbilities();
			}

			// Send position
			SendMovement();
		}

		private void Move(Vec2d movement) {
			double gravity = 0.08;

			double speedMultiplier = 0.91;
			double friction = 0.6;
			
			// On ground
			if (onGround) {
				speedMultiplier *= friction;
			}

			Vec3d newVelocity = Move(movement, friction);

			// Has gravity
			if (!abilities.flying) {
				newVelocity.y -= gravity;
			}

			velocity = newVelocity * .(speedMultiplier, 0.98, speedMultiplier);
		}

		private Vec3d Move(Vec2d movement, double friction) {
			// Calculate velocity
			velocity += CalculateVelocity(movement, FrictionToMovement(friction));

			// Move
			if (gamemode == .Spectator) {
				pos += velocity;
				onGround = false;
			}
			else {
				PhysicsResult result = scope .();
				BlockCollision.HandlePhysics(AABB, velocity, pos, Meteorite.INSTANCE.world, result);

				pos = result.newPosition;
				velocity = result.newVelocity;
				onGround = result.isOnGround;

				// Stop sprinting if collided horizontally
				if (result.collisionX || result.collisionZ) {
					sprinting = false;
				}
			}

			return velocity;
		}

		private double FrictionToMovement(double friction) {
			if (onGround) {
				return GetAttribute(EntityAttributes.GENERIC_MOVEMENT_SPEED, abilities.walkingSpeed) * (0.21600002 / Math.Pow(friction, 3));
			}

			return flyingSpeed;
		}

		private Vec3d CalculateVelocity(Vec2d movement, double speed) {
			if (movement.IsZero) {
				return .();
			}

			Vec3d velocity = .(movement.x, 0, movement.y);

			if (velocity.Dot(velocity) > 1) {
				velocity = velocity.Normalize();
			}

			velocity *= speed;

			double yawRad = yaw * Math.DEG2RADd;
			double sin = Math.Sin(yawRad);
			double cos = Math.Cos(yawRad);

			return .(velocity.x * cos - velocity.z * sin, velocity.y, velocity.z * cos + velocity.x * sin);
		}

		private void SendAbilities() {
			Meteorite.INSTANCE.connection.Send(scope PlayerAbilitiesC2SPacket(abilities));
		}

		private void SendMovement() {
			// Sprinting
			if (sprinting != lastSentSprinting) {
				Meteorite.INSTANCE.connection.Send(scope PlayerCommandC2SPacket(this, sprinting ? .StartSprinting : .StopSprinting));
				lastSentSprinting = sprinting;
			}

			// Position
			sendPositionTimer++;

			bool positionChanged = (pos - lastSentPos).Length > 2.0E-4 || sendPositionTimer >= 20;
			bool rotationChanged = (yaw - lastSentYaw) != 0 || (pitch - lastSentPitch) != 0;
			bool onGroundChanged = onGround != lastSentOnGround;

			// TODO: Figure out On Ground property
			if (positionChanged || rotationChanged || onGroundChanged) {
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

			lastSentOnGround = onGround;
		}

		public void SetAttributes(EntityAttribute[] attributes) {
			for (EntityAttribute attribute in this.attributes.Values) {
				delete attribute;
			}

			this.attributes.Clear();

			for (EntityAttribute attribute in attributes) {
				this.attributes[attribute.name] = attribute;
			}
		}

		public double GetAttribute(StringView name, double defaultValue) {
			EntityAttribute attribute;
			if (!attributes.TryGetValue(name, out attribute)) return defaultValue;

			double value = attribute.baseValue;

			for (let modifier in attribute.modifiers) {
				switch (modifier.operation) {
				case .Add:				value += modifier.amount;
				case .MultiplyBase:		value += attribute.baseValue * (modifier.amount + 1);
				case .MultiplyTotal:	value *= modifier.amount + 1;
				}
			}

			return value;
		}
	}
}