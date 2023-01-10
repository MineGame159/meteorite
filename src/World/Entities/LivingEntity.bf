using System;

using Cacti;

namespace Meteorite{
	class LivingEntity : Entity {
		protected Vec3d deltaMovement;

		public this(EntityType type, int id, Vec3d pos) : base(type, id, pos) {}

		public override void Tick() {
			if (Math.Abs(deltaMovement.x) < 0.003) deltaMovement.x = 0;
			if (Math.Abs(deltaMovement.y) < 0.003) deltaMovement.y = 0;
			if (Math.Abs(deltaMovement.z) < 0.003) deltaMovement.z = 0;

			base.Tick();
			TickMovement();
		}

		protected virtual void TickMovement() {}
	}
}