using System;
using System.Collections;

using Cacti;

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

		public void End(CommandBuffer cmds, Camera camera) {
			cmds.Bind(Gfxa.ENTITY_PIPELINE);
			FrameUniforms.Bind(cmds);

			for (let pair in provider.Meshes) {
				Meteorite.INSTANCE.textures.Bind(cmds, pair.key);

				cmds.Draw(pair.value.End(.Frame, Buffers.QUAD_INDICES));
			}

			provider.End();
		}
	}
}