using System;

namespace Meteorite {
	class SalmonEntityRenderer : MobEntityRenderer {
		public this() : base(null) {}

		public override void Render(MatrixStack matrices, Entity entity, NamedMeshBuilderProvider provider, float tickDelta) {
		}

		public override String GetTexture(Entity entity) => "entity/fish/salmon.png";

		protected override void SetupRotations(Entity entity, MatrixStack matrices, float ageInTicks, float rotationYaw, float partialTicks) {
			base.SetupRotations(entity, matrices, ageInTicks, rotationYaw, partialTicks);

			float f = 1;
			float g = 1;
			if (!entity.IsInWater()) {
				f = 1.3f;
				g = 1.7f;
			}

			float h = f * 4.3f * Math.Sin(g * 0.6f * ageInTicks);
			matrices.Rotate(.(0, 1, 0), h);
			matrices.Translate(.(0, 0, -0.4f));
			
			if (!entity.IsInWater()) {
				matrices.Translate(.(0.2f, 0.1f, 0));
				matrices.Rotate(.(0, 0, 1), 90);
			}
		}
	}
}