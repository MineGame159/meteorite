using System;

namespace Meteorite {
	abstract class MobEntityRenderer : LivingEntityRenderer {
		public this(EntityModel model) : base(model) {}
	}
}