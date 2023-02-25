using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

class WorldRenderer {
	private Meteorite me = .INSTANCE;

	public ChunkRenderer chunkRenderer = new .() ~ delete _;

	public void RenderPre(RenderPass pass, float tickDelta, float delta) {
		chunkRenderer.Setup();

		SkyRenderer.Render(pass, me.world, me.camera, tickDelta);
	}

	public void Render(RenderPass pass, float tickDelta, float delta) {
		pass.PushDebugGroup("World");

		chunkRenderer.RenderLayer(pass, .Solid);
		RenderBlockEntities(pass, tickDelta);
		RenderEntities(pass, tickDelta);
		chunkRenderer.RenderLayer(pass, .Transparent);
		
		pass.PopDebugGroup();
	}

	public void RenderPost(RenderPass pass, float tickDelta, float delta) {
		if (me.player != null && me.player.selection != null && !me.player.selection.missed) RenderBlockSelection(pass);
		if (me.options.chunkBoundaries) RenderChunkBoundaries(pass);
	}

	[Tracy.Profile]
	private void RenderBlockEntities(RenderPass pass, float tickDelta) {
		pass.PushDebugGroup("Block Entities");
		me.blockEntityRenderDispatcher.Begin();
		
		for (Chunk chunk in chunkRenderer) {
			for (BlockEntity blockEntity in chunk.BlockEntities) {
				me.blockEntityRenderDispatcher.Render(blockEntity, 0, tickDelta);
			}
		}

		me.blockEntityRenderDispatcher.End(pass, me.camera);
		pass.PopDebugGroup();
	}

	[Tracy.Profile]
	private void RenderEntities(RenderPass pass, float tickDelta) {
		pass.PushDebugGroup("Entities");
		pass.Bind(Gfxa.ENTITY_PIPELINE);
		pass.Bind(0, FrameUniforms.Descriptor);
		pass.Bind(1, Gfxa.PIXEL_DESCRIPTOR);
		pass.Bind(2, me.lightmapManager.Descriptor);

		MeshBuilder mb = scope .(false);
		Meteorite me = Meteorite.INSTANCE;

		for (Entity entity in me.world.Entities) {
			if (entity == me.player && !ShouldRenderSelf()) continue;

			entity.Render(mb, tickDelta);
		}

		pass.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));

		pass.PopDebugGroup();
	}

	private bool ShouldRenderSelf() {
		return false;
		//return me.player.gamemode == .Spectator;
	}

	[Tracy.Profile]
	private void RenderBlockSelection(RenderPass pass) {
		Vec3i pos = me.player.selection.blockPos;

		BlockState blockState = me.world.GetBlock(pos);
		if (blockState == null) return;

		VoxelShape shape = blockState.Shape;
		if (shape == null) return;

		pass.Bind(Gfxa.LINES_PIPELINE);

		Mat4 projectionView = me.camera.proj * me.camera.viewRotationOnly;
		pass.SetPushConstants(projectionView);

		Color color = .(255, 255, 255, 100);
		MeshBuilder mb = scope .();

		AABB aabb = shape.GetBoundingBox();
		Vec3d min = .(pos.x, pos.y, pos.z) + aabb.min;
		Vec3d max = .(pos.x, pos.y, pos.z) + aabb.max;

		Vec3f cameraPos = (.) me.camera.pos;

		uint32 ib1 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) min.y, (.) min.z) - cameraPos, color));
		uint32 ib2 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) min.y, (.) max.z) - cameraPos, color));
		uint32 ib3 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) min.y, (.) max.z) - cameraPos, color));
		uint32 ib4 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) min.y, (.) min.z) - cameraPos, color));

		uint32 it1 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) max.y, (.) min.z) - cameraPos, color));
		uint32 it2 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) max.y, (.) max.z) - cameraPos, color));
		uint32 it3 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) max.y, (.) max.z) - cameraPos, color));
		uint32 it4 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) max.y, (.) min.z) - cameraPos, color));

		mb.Line(ib1, ib2);
		mb.Line(ib2, ib3);
		mb.Line(ib3, ib4);
		mb.Line(ib4, ib1);

		mb.Line(it1, it2);
		mb.Line(it2, it3);
		mb.Line(it3, it4);
		mb.Line(it4, it1);

		mb.Line(ib1, it1);
		mb.Line(ib2, it2);
		mb.Line(ib3, it3);
		mb.Line(ib4, it4);

		pass.Draw(mb.End());
	}

	[Tracy.Profile]
	private void RenderChunkBoundaries(RenderPass pass) {
		pass.PushDebugGroup("Chunk Boundaries");
		pass.Bind(Gfxa.LINES_PIPELINE);

		Mat4 projectionView = me.camera.proj * me.camera.viewRotationOnly;
		pass.SetPushConstants(projectionView);

		MeshBuilder mb = scope .();

		int x = ((.) me.camera.pos.x >> 4) * 16;
		int z = ((.) me.camera.pos.z >> 4) * 16;

		Color color1 = .(225, 25, 25);
		Color color2 = .(225, 225, 25);

		Line(mb, x, z, color1);
		Line(mb, x + 16, z, color1);
		Line(mb, x, z + 16, color1);
		Line(mb, x + 16, z + 16, color1);

		x -= 16;
		z -= 16;

		Line(mb, x, z, color2);
		Line(mb, x + 48, z, color2);
		Line(mb, x, z + 48, color2);
		Line(mb, x + 48, z + 48, color2);

		Line(mb, x, z, color2);
		Line(mb, x + 16, z, color2);
		Line(mb, x + 32, z, color2);

		Line(mb, x, z, color2);
		Line(mb, x, z + 16, color2);
		Line(mb, x, z + 32, color2);

		Line(mb, x + 48, z, color2);
		Line(mb, x + 48, z + 16, color2);
		Line(mb, x + 48, z + 32, color2);

		Line(mb, x, z + 48, color2);
		Line(mb, x + 16, z + 48, color2);
		Line(mb, x + 32, z + 48, color2);

		pass.Draw(mb.End());

		pass.PopDebugGroup();
	}

	private void Line(MeshBuilder mb, int x, int z, Color color) {
		Vec3f cameraPos = (.) me.camera.pos;

		mb.Line(
			mb.Vertex<PosColorVertex>(.(.(x, 0, z) - cameraPos, color)),
			mb.Vertex<PosColorVertex>(.(.(x, me.world.dimension.height, z) - cameraPos, color))
		);
	}
}