using System;

using Cacti;
using Cacti.Json;

namespace Meteorite {
	abstract class EntityRenderer {
		public abstract String GetTexture(Entity entity);

		public abstract void Render(MatrixStack matrices, Entity entity, NamedMeshBuilderProvider provider, float tickDelta);
		
		protected ModelPart Load(StringView name) {
			Json json = Meteorite.INSTANCE.resources.ReadJson(scope $"models/entity/{name}.json");
			defer json.Dispose();

			return ModelPart.Parse(json);
		}
	}
}