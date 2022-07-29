using System;
using System.Collections;

namespace Meteorite {
	class EntityRenderDispatcher {
		private Dictionary<EntityType, EntityRenderer> renderers = new .() ~ DeleteDictionaryAndValues!(_);

		private NamedMeshBuilderProvider provider = new .() ~ delete _;
		private MatrixStack matrices = new .() ~ delete _;

		public this() {
			renderers[EntityTypes.SALMON] = new SalmonEntityRenderer();
		}

		public void Begin() {
		}

		public void Render(Entity entity, float tickDelta) {


		}

		public void End(RenderPass pass, Camera camera) {
			Gfxa.ENTITY_PIPELINE.Bind(pass);
			FrameUniforms.Bind(pass);

			for (let pair in provider.Meshes) {
				Meteorite.INSTANCE.textures.Bind(pass, pair.key);

				((ImmediateMeshBuilder) pair.value).[Friend]pass = pass; // cope about it
				pair.value.Finish();
			}

			provider.End();
		}
	}
}