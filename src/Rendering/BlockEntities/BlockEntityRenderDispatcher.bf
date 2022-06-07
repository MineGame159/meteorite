using System;
using System.Collections;

namespace Meteorite {
	class BlockEntityRenderDispatcher {
		private Dictionary<BlockEntityType, BlockEntityRenderer> renderers = new .() ~ DeleteDictionaryAndValues!(_);

		private NamedMeshProvider provider = new .() ~ delete _;
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

			Mat4 mat = camera.proj * camera.view;
			pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &mat);

			for (let pair in provider.Meshes) {
				Meteorite.INSTANCE.textures.Bind(pass, pair.key);

				pair.value.End();
				pair.value.Render(pass);
			}

			provider.End();
		}
	}
}