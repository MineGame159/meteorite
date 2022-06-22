using System;
using System.Collections;

namespace Meteorite {
	class BlockEntityRenderDispatcher {
		private Dictionary<BlockEntityType, BlockEntityRenderer> renderers = new .() ~ DeleteDictionaryAndValues!(_);

		private NamedMeshBuilderProvider provider = new .() ~ delete _;
		private MatrixStack matrices = new .() ~ delete _;

		public this() {
			renderers[BlockEntityTypes.CHEST] = new ChestBlockEntityRenderer();
			renderers[BlockEntityTypes.TRAPPED_CHEST] = new ChestBlockEntityRenderer();
			renderers[BlockEntityTypes.ENDER_CHEST] = new ChestBlockEntityRenderer();
			renderers[BlockEntityTypes.BELL] = new BellBlockEntityRenderer();
		}

		public void Begin() {
			
		}

		public void Render(BlockEntity blockEntity, float tickDelta) {
			matrices.Push();
			matrices.Translate(.(blockEntity.pos.x, blockEntity.pos.y, blockEntity.pos.z));

			BlockState blockState = Meteorite.INSTANCE.world.GetBlock(blockEntity.pos.x, blockEntity.pos.y, blockEntity.pos.z);

			BlockEntityRenderer renderer = renderers[blockEntity.type];
			renderer.Render(matrices, blockState, blockEntity, provider, tickDelta);
			
			matrices.Pop();
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