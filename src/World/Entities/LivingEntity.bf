using System;

using Cacti;

namespace Meteorite{
	class LivingEntity : Entity {
		public this(EntityType type, int32 id, Vec3d pos) : base(type, id, pos) {}

		public override void Tick() {
			base.Tick();
			TickMovement();
		}

		protected virtual void TickMovement() {}
	}
}