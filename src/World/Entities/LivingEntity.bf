using System;

using Cacti;

namespace Meteorite;

class LivingEntity : Entity {
	public float health;

	public this(EntityType type, int32 id, Vec3d pos) : base(type, id, pos) {
		health = GetMaxHealth();
	}

	public override void Tick() {
		base.Tick();
		TickMovement();
	}

	protected virtual void TickMovement() {}

	// TODO: Move entity attributes from ClientPlayerEntity to LivingEntity
	public virtual float GetMaxHealth() => 20;
}