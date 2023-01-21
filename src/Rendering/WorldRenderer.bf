using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class WorldRenderer {
		private Meteorite me = .INSTANCE;

		public ChunkRenderer chunkRenderer = new .() ~ delete _;

		public void RenderPre(CommandBuffer cmds, float tickDelta, float delta) {
			chunkRenderer.Setup();

			SkyRenderer.Render(cmds, me.world, me.camera, tickDelta);
		}

		public void Render(CommandBuffer cmds, float tickDelta, float delta) {
			cmds.PushDebugGroup("World");

			chunkRenderer.RenderLayer(cmds, .Solid);
			RenderBlockEntities(cmds, tickDelta);
			RenderEntities(cmds, tickDelta);
			chunkRenderer.RenderLayer(cmds, .Transparent);
			
			cmds.PopDebugGroup();
		}

		public void RenderPost(CommandBuffer cmds, float tickDelta, float delta) {
			if (me.player != null && me.player.selection != null && !me.player.selection.missed) RenderBlockSelection(cmds);
			if (me.options.chunkBoundaries) RenderChunkBoundaries(cmds);
		}

		private void RenderBlockEntities(CommandBuffer cmds, float tickDelta) {
			cmds.PushDebugGroup("Block Entities");
			me.blockEntityRenderDispatcher.Begin();
			
			for (Chunk chunk in chunkRenderer) {
				for (BlockEntity blockEntity in chunk.BlockEntities) {
					me.blockEntityRenderDispatcher.Render(blockEntity, 0, tickDelta);
				}
			}

			me.blockEntityRenderDispatcher.End(cmds, me.camera);
			cmds.PopDebugGroup();
		}

		private void RenderEntities(CommandBuffer cmds, float tickDelta) {
			cmds.PushDebugGroup("Entities");
			cmds.Bind(Gfxa.ENTITY_PIPELINE);
			FrameUniforms.Bind(cmds);
			cmds.Bind(Gfxa.PIXEL_SET, 1);
			Meteorite.INSTANCE.lightmapManager.Bind(cmds, 2);

			MeshBuilder mb = scope .(false);
			Meteorite me = Meteorite.INSTANCE;

			for (Entity entity in me.world.Entities) {
				if (entity == me.player && !ShouldRenderSelf()) continue;

				entity.Render(mb, tickDelta);
			}

			cmds.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));

			cmds.PopDebugGroup();
		}

		private bool ShouldRenderSelf() {
			return false;
			//return me.player.gamemode == .Spectator;
		}

		private void RenderBlockSelection(CommandBuffer cmds) {
			Vec3i pos = me.player.selection.blockPos;
			BlockState blockState = me.world.GetBlock(pos);

			if (blockState == null) return;

			cmds.Bind(Gfxa.LINES_PIPELINE);

			Mat4 projectionView = me.camera.proj * me.camera.view;
			cmds.SetPushConstants(projectionView);

			Color color = .(255, 255, 255, 100);
			MeshBuilder mb = scope .();

			AABB aabb = blockState.Shape.GetBoundingBox();
			Vec3d min = .(pos.x, pos.y, pos.z) + aabb.min;
			Vec3d max = .(pos.x, pos.y, pos.z) + aabb.max;

			uint32 ib1 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) min.y, (.) min.z), color));
			uint32 ib2 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) min.y, (.) max.z), color));
			uint32 ib3 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) min.y, (.) max.z), color));
			uint32 ib4 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) min.y, (.) min.z), color));

			uint32 it1 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) max.y, (.) min.z), color));
			uint32 it2 = mb.Vertex<PosColorVertex>(.(.((.) min.x, (.) max.y, (.) max.z), color));
			uint32 it3 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) max.y, (.) max.z), color));
			uint32 it4 = mb.Vertex<PosColorVertex>(.(.((.) max.x, (.) max.y, (.) min.z), color));

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

			cmds.Draw(mb.End());
		}

		private void RenderChunkBoundaries(CommandBuffer cmds) {
			cmds.PushDebugGroup("Chunk Boundaries");
			cmds.Bind(Gfxa.LINES_PIPELINE);

			Mat4 projectionView = me.camera.proj * me.camera.view;
			cmds.SetPushConstants(projectionView);

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

			cmds.Draw(mb.End());

			cmds.PopDebugGroup();
		}

		private void Line(MeshBuilder mb, int x, int z, Color color) {
			mb.Line(
				mb.Vertex<PosColorVertex>(.(.(x, 0, z), color)),
				mb.Vertex<PosColorVertex>(.(.(x, me.world.dimension.height, z), color))
			);
		}
	}
}