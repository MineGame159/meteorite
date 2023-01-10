using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class WorldRenderer {
		private Meteorite me = .INSTANCE;

		private ThreadPool threadPool = new .();

		private List<Chunk> visibleChunks = new .() ~ delete _;

		public Counter<int> chunkUpdates = new .(20) ~ delete _;
		public int renderedChunks;

		private int chunkUpdatesThisTick;
		private bool shuttingDown;

		public ~this() {
			shuttingDown = true;

			// Thread pool needs to be deleted before ending un-uploaded meshes
			delete threadPool;

			for (Chunk chunk in me.world.Chunks) {
				if (chunk.status == .Upload) {
					chunk.solidMb.Cancel();
					DeleteAndNullify!(chunk.solidMb);

					chunk.transparentMb.Cancel();
					DeleteAndNullify!(chunk.solidMb);
				}
			}
		}

		public void Tick() {
			chunkUpdates.Add(chunkUpdatesThisTick);
			chunkUpdatesThisTick = 0;
		}

		public void RenderPre(CommandBuffer cmds, float tickDelta, float delta) {
			SetupChunks();

			SkyRenderer.Render(cmds, me.world, me.camera, tickDelta);
		}

		public void Render(CommandBuffer cmds, float tickDelta, float delta) {
			cmds.PushDebugGroup("World");

			RenderChunks(cmds, true, Gfxa.CHUNK_PIPELINE, delta);
			RenderBlockEntities(cmds, tickDelta);
			RenderEntities(cmds, tickDelta);
			RenderChunks(cmds, false, Gfxa.CHUNK_TRANSPARENT_PIPELINE, delta);
			
			cmds.PopDebugGroup();
		}

		public void RenderPost(CommandBuffer cmds, float tickDelta, float delta) {
			if (me.player != null && me.player.selection != null && !me.player.selection.missed) RenderBlockSelection(cmds);
			if (me.options.chunkBoundaries) RenderChunkBoundaries(cmds);

			if (me.player != null) {
				cmds.Bind(Gfxa.LINES_PIPELINE);

				Mat4 projectionView = me.camera.proj * me.camera.view;
				cmds.SetPushConstants(projectionView);

				MeshBuilder mb = scope .();

				me.world.GetPossibleCollisions(me.player.GetAABB(), scope (pos, shape) => {
					Color c = .(255, 255, 255);

					float x = (.) pos.x + 0.5f;
					float y = (.) pos.y + 0.5f;
					float z = (.) pos.z + 0.5f;
					float s = 0.05f;

					mb.Line(
						mb.Vertex<PosColorVertex>(.(.((.) x - s, (.) y, (.) z), c)),
						mb.Vertex<PosColorVertex>(.(.((.) x + s, (.) y, (.) z), c))
					);

					mb.Line(
						mb.Vertex<PosColorVertex>(.(.((.) x, (.) y - s, (.) z), c)),
						mb.Vertex<PosColorVertex>(.(.((.) x, (.) y + s, (.) z), c))
					);

					mb.Line(
						mb.Vertex<PosColorVertex>(.(.((.) x, (.) y, (.) z - s), c)),
						mb.Vertex<PosColorVertex>(.(.((.) x, (.) y, (.) z + s), c))
					);
				});

				cmds.Draw(mb.End());
			}
		}

		private void SetupChunks() {
			visibleChunks.Clear();
			renderedChunks = 0;

			// Frustrum cull and schedule rebuilds
			for (Chunk chunk in me.world.Chunks) {
				if (chunk.dirty && (chunk.status == .NotReady || chunk.status == .Ready) && me.world.IsChunkLoaded(chunk.pos.x + 1, chunk.pos.z) && me.world.IsChunkLoaded(chunk.pos.x - 1, chunk.pos.z) && me.world.IsChunkLoaded(chunk.pos.x, chunk.pos.z + 1) && me.world.IsChunkLoaded(chunk.pos.x, chunk.pos.z - 1)) {
					chunk.status = .Building;

					chunk.solidMb = new .(false);
					chunk.transparentMb = new .(false);

					threadPool.Add(new () => GenerateChunkMesh(chunk));
					chunkUpdatesThisTick++;
				}
				if (chunk.status == .Upload) {
					chunk.status = .Uploading;

					chunk.solidMesh = chunk.solidMb.End(.ProvidedResize(chunk.SolidVbo), Buffers.QUAD_INDICES, new () => chunk.status = .Ready);
					DeleteAndNullify!(chunk.solidMb);

					chunk.transparentMesh = chunk.transparentMb.End(.ProvidedResize(chunk.TransparentVbo), Buffers.QUAD_INDICES, new () => chunk.status = .Ready);
					DeleteAndNullify!(chunk.transparentMb);
				}

				if (me.camera.IsBoxVisible(chunk.min, chunk.max)) {
					visibleChunks.Add(chunk);
					renderedChunks++;
				}
			}

			// Sort chunks
			if (me.options.sortChunks) {
				visibleChunks.Sort(scope (lhs, rhs) => {
					double x1 = (lhs.pos.x + 0.5) * 16 - me.camera.pos.x;
					double z1 = (lhs.pos.z + 0.5) * 16 - me.camera.pos.z;
					double dist1 = x1 * x1 + z1 * z1;

					double x2 = (rhs.pos.x + 0.5) * 16 - me.camera.pos.x;
					double z2 = (rhs.pos.z + 0.5) * 16 - me.camera.pos.z;
					double dist2 = x2 * x2 + z2 * z2;

					return dist2.CompareTo(dist1);
				});
			}
		}

		[Inline]
		private void UpdateChunkPushConstants(CommandBuffer cmds, Chunk chunk, float delta) {
			if (chunk.goingDown) {
				chunk.yOffset -= delta * 20;
			}
			else if (chunk.yOffset < 0) {
				chunk.yOffset += delta * 20;
				if (chunk.yOffset > 0) chunk.yOffset = 0;
			}

			Vec3f chunkPos = .(chunk.pos.x * Section.SIZE, (.) chunk.yOffset, chunk.pos.z * Section.SIZE);
			cmds.SetPushConstants(chunkPos);
		}

		private void RenderChunks(CommandBuffer cmds, bool solid, Pipeline pipeline, float delta) {
			cmds.PushDebugGroup(scope $"Chunks - {solid ? ("Solid") : ("Transparent")}");
			cmds.Bind(pipeline);
			FrameUniforms.Bind(cmds);
			Meteorite.INSTANCE.textures.Bind(cmds, me.options.mipmaps);

			for (Chunk chunk in visibleChunks) {
				if (chunk.status == .NotReady) continue;

				UpdateChunkPushConstants(cmds, chunk, delta);

				if (solid) cmds.Draw(chunk.solidMesh);
				else cmds.Draw(chunk.transparentMesh);
			}

			cmds.PopDebugGroup();
		}

		private void RenderBlockEntities(CommandBuffer cmds, float tickDelta) {
			cmds.PushDebugGroup("Block Entities");
			me.blockEntityRenderDispatcher.Begin();

			for (Chunk chunk in visibleChunks) {
				for (BlockEntity blockEntity in chunk.BlockEntities) {
					me.blockEntityRenderDispatcher.Render(blockEntity, chunk.yOffset, tickDelta);
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

			MeshBuilder mb = scope .(false);
			Meteorite me = Meteorite.INSTANCE;

			for (Entity entity in me.world.Entities) {
				if (entity == me.player && me.player.gamemode != .Spectator) continue;

				entity.Render(mb, tickDelta);
			}

			cmds.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));

			cmds.PopDebugGroup();
		}

		private void RenderBlockSelection(CommandBuffer cmds) {
			cmds.Bind(Gfxa.LINES_PIPELINE);

			Mat4 projectionView = me.camera.proj * me.camera.view;
			cmds.SetPushConstants(projectionView);

			Color color = .(255, 255, 255, 100);
			MeshBuilder mb = scope .();

			Vec3i pos = me.player.selection.blockPos;
			AABB aabb = me.world.GetBlock(pos).Shape.GetBoundingBox();
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
				mb.Vertex<PosColorVertex>(.(.(x, me.world.height, z), color))
			);
		}

		private void GenerateChunkMesh(Chunk chunk) {
			int minI = (.) chunk.min.y / Section.SIZE;
			int maxI = Math.Min((int) chunk.max.y / Section.SIZE, me.world.SectionCount - 1);

			for (int i = minI; i <= maxI; i++) {
				Section section = chunk.GetSection(i);
				if (section == null) continue;

				int sectionY = i * Section.SIZE;

				for (int x < Section.SIZE) {
					for (int y < Section.SIZE) {
						for (int z < Section.SIZE) {
							int by = sectionY + y;
							int sy = y % Section.SIZE;
							BlockState blockState = section.Get(x, sy, z);

							BlockRenderer.Render(me.world, chunk, x, by, z, blockState, section.GetBiome(x, sy, z));
						}
					}
				}
			}

			if (shuttingDown) {
				chunk.solidMb.Cancel();
				DeleteAndNullify!(chunk.solidMb);

				chunk.transparentMb.Cancel();
				DeleteAndNullify!(chunk.solidMb);

				chunk.status = .Ready;
			}
			else {
				chunk.status = .Upload;
			}

			chunk.dirty = false;

			if (chunk.firstBuild) {
				chunk.yOffset = -16;
				chunk.firstBuild = false;
			}
		}
	}
}