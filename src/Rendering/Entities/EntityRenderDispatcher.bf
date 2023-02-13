using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;

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
			pass.Bind(Gfxa.ENTITY_PIPELINE);
			pass.Bind(0, FrameUniforms.Descriptor);

			for (let pair in provider.Meshes) {
				pass.Bind(1, Meteorite.INSTANCE.textures.GetDescriptor(pair.key));

				pass.Draw(pair.value.End(.Frame, Buffers.QUAD_INDICES));
			}

			provider.End();
		}
	}
}