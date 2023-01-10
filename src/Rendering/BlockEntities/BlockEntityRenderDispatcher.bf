using System;
using System.Collections;

using Cacti;

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

		public void Render(BlockEntity blockEntity, double offsetY, float tickDelta) {
			matrices.Push();
			matrices.Translate(.(blockEntity.pos.x, blockEntity.pos.y + (.) offsetY, blockEntity.pos.z));

			BlockState blockState = Meteorite.INSTANCE.world.GetBlock(blockEntity.pos.x, blockEntity.pos.y, blockEntity.pos.z);

			BlockEntityRenderer renderer = renderers[blockEntity.type];
			renderer.Render(matrices, blockState, blockEntity, provider, tickDelta);
			
			matrices.Pop();
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