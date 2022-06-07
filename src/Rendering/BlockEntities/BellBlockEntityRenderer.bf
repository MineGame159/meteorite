using System;

namespace Meteorite {
	class BellBlockEntityRenderer : BlockEntityRenderer {
		private ModelPart model ~ delete _;
		private ModelPart body;

		public this() {
			model = Load("bell");
			body = model.GetChild("bell_body");
		}

		public override void Render(MatrixStack matrices, BlockState blockState, BlockEntity _, NamedMeshProvider provider, float tickDelta) {
			body.Render(matrices, provider.Get("entity/bell/bell_body.png"));
		}
	}
}