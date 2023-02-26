using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

class BlockEntityRenderDispatcher {
	private Dictionary<BlockEntityType, BlockEntityRenderer> renderers = new .() ~ DeleteDictionaryAndValues!(_);

	private NamedMeshBuilderProvider provider = new .() ~ delete _;
	private MatrixStack matrices = new .() ~ delete _;
	
	[Tracy.Profile]
	public this() {
		renderers[BlockEntityTypes.CHEST] = new ChestBlockEntityRenderer();
		renderers[BlockEntityTypes.TRAPPED_CHEST] = new ChestBlockEntityRenderer();
		renderers[BlockEntityTypes.ENDER_CHEST] = new ChestBlockEntityRenderer();
		renderers[BlockEntityTypes.BELL] = new BellBlockEntityRenderer();
	}

	public void Begin() {
		
	}
	
	[Tracy.Profile]
	public void Render(BlockEntity blockEntity, double offsetY, float tickDelta) {
		matrices.Push();
		matrices.Translate(.(blockEntity.pos.x, blockEntity.pos.y + (.) offsetY, blockEntity.pos.z));
		matrices.Translate((.) -Meteorite.INSTANCE.camera.pos);

		BlockState blockState = Meteorite.INSTANCE.world.GetBlock(blockEntity.pos.x, blockEntity.pos.y, blockEntity.pos.z);

		BlockEntityRenderer renderer = renderers[blockEntity.type];
		renderer.Render(matrices, blockState, blockEntity, provider, tickDelta);
		
		matrices.Pop();
	}
	
	[Tracy.Profile]
	public void End(RenderPass pass, Camera camera) {
		pass.Bind(Gfxa.ENTITY_PIPELINE);
		pass.Bind(0, FrameUniforms.Descriptor);
		pass.Bind(2, Meteorite.INSTANCE.lightmapManager.Descriptor);

		for (let pair in provider.Meshes) {
			pass.Bind(1, Meteorite.INSTANCE.textures.GetDescriptor(pair.key));

			pass.Draw(pair.value.End(.Frame, Buffers.QUAD_INDICES));
		}

		provider.End();
	}
}