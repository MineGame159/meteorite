using System;

namespace Meteorite {
	abstract class BlockEntityRenderer {
		public abstract void Render(MatrixStack matrices, BlockState blockState, BlockEntity _, NamedMeshProvider provider, float tickDelta);
		
		protected ModelPart Load(StringView name) {
			Json json = Meteorite.INSTANCE.resources.ReadJson(scope $"models/block_entity/{name}.json");
			defer json.Dispose();

			return ModelPart.Parse(json);
		}
	}
}