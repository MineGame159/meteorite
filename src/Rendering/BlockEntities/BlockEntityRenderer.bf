using System;

using Cacti;
using Cacti.Json;

namespace Meteorite;

abstract class BlockEntityRenderer {
	public abstract void Render(MatrixStack matrices, BlockState blockState, BlockEntity _, NamedMeshBuilderProvider provider, float tickDelta);
	
	protected ModelPart Load(StringView name) {
		Json json = Meteorite.INSTANCE.resources.ReadJson(scope $"models/block_entity/{name}.json");
		defer json.Dispose();

		return ModelPart.Parse(json);
	}

	protected uint32 GetLightUv(BlockState blockState, BlockEntity blockEntity) {
		if (blockState.emissive) return BlockRenderer.FULL_BRIGHT_UV;

		Chunk chunk = Meteorite.INSTANCE.world.GetChunk(blockEntity.pos.x >> 4, blockEntity.pos.z >> 4);
		if (chunk == null) return BlockRenderer.FULL_BRIGHT_UV;

		int x = blockEntity.pos.x & 15;
		int z = blockEntity.pos.z & 15;

		uint32 sky = (.) chunk.GetLight(.Sky, x, blockEntity.pos.y, z);
		uint32 block = (.) chunk.GetLight(.Block, x, blockEntity.pos.y, z);

		if (block < blockState.luminance) block = blockState.luminance;

		return BlockRenderer.PackLightmapUv(sky, block);
	}
}