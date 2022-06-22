using System;
using System.Collections;

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
					chunk.mesh.Build().Cancel();
					chunk.meshTransparent.Build().Cancel();
				}
			}
		}

		public void Tick() {
			chunkUpdates.Add(chunkUpdatesThisTick);
			chunkUpdatesThisTick = 0;
		}

		public void RenderPre(RenderPass pass, float tickDelta, float delta) {
			SetupChunks();

			SkyRenderer.Render(pass, me.world, me.camera, tickDelta);
		}

		public void Render(RenderPass pass, float tickDelta, float delta) {
			pass.PushDebugGroup("World");

			RenderChunks(pass, true, Gfxa.CHUNK_PIPELINE, delta);
			RenderBlockEntities(pass, tickDelta);
			RenderEntities(pass, tickDelta);
			RenderChunks(pass, false, Gfxa.CHUNK_TRANSPARENT_PIPELINE, delta);

			pass.PopDebugGroup();
		}

		public void RenderPost(RenderPass pass, float tickDelta, float delta) {
			if (me.player != null && me.player.selection != null && !me.player.selection.missed) RenderBlockSelection(pass);
			if (me.options.chunkBoundaries) RenderChunkBoundaries(pass);

			if (me.player != null) {
				Gfxa.LINES_PIPELINE.Bind(pass);

				Mat4 projectionView = me.camera.proj * me.camera.view;
				pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &projectionView);

				MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass);

				me.world.GetPossibleCollisions(me.player.GetAABB(), scope (pos, shape) => {
					Color c = .(255, 255, 255);

					float x = (.) pos.x + 0.5f;
					float y = (.) pos.y + 0.5f;
					float z = (.) pos.z + 0.5f;
					float s = 0.05f;

					mb.Line(
						mb.Vec3(.((.) x - s, (.) y, (.) z)).Color(c).Next(),
						mb.Vec3(.((.) x + s, (.) y, (.) z)).Color(c).Next()
					);

					mb.Line(
						mb.Vec3(.((.) x, (.) y - s, (.) z)).Color(c).Next(),
						mb.Vec3(.((.) x, (.) y + s, (.) z)).Color(c).Next()
					);

					mb.Line(
						mb.Vec3(.((.) x, (.) y, (.) z - s)).Color(c).Next(),
						mb.Vec3(.((.) x, (.) y, (.) z + s)).Color(c).Next()
					);
				});

				mb.Finish();
			}
		}

		private void SetupChunks() {
			visibleChunks.Clear();
			renderedChunks = 0;

			// Frustrum cull and schedule rebuilds
			for (Chunk chunk in me.world.Chunks) {
				if (chunk.dirty && chunk.status == .Ready && me.world.IsChunkLoaded(chunk.pos.x + 1, chunk.pos.z) && me.world.IsChunkLoaded(chunk.pos.x - 1, chunk.pos.z) && me.world.IsChunkLoaded(chunk.pos.x, chunk.pos.z + 1) && me.world.IsChunkLoaded(chunk.pos.x, chunk.pos.z - 1)) {
					chunk.status = .Building;
					if (chunk.mesh == null) {
						chunk.mesh = new Mesh(Buffers.QUAD_INDICES);
						chunk.meshTransparent = new Mesh();
					}

					threadPool.Add(new () => GenerateChunkMesh(chunk));
					chunkUpdatesThisTick++;
				}
				if (chunk.status == .Upload) {
					chunk.meshTransparent.Build().Finish();
					chunk.mesh.Build().Finish();
					chunk.status = .Ready;
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
		private void UpdateChunkPushConstants(RenderPass pass, Chunk chunk, ref ChunkPushConstants pc, float delta) {
			if (chunk.goingDown) {
				chunk.yOffset -= delta * 20;
			}
			else if (chunk.yOffset < 0) {
				chunk.yOffset += delta * 20;
				if (chunk.yOffset > 0) chunk.yOffset = 0;
			}

			pc.chunkPos = .(chunk.pos.x * Section.SIZE, (.) chunk.yOffset, chunk.pos.z * Section.SIZE);
			pass.SetPushConstants(.Vertex, 0, sizeof(ChunkPushConstants), &pc);
		}

		private void RenderChunks(RenderPass pass, bool solid, Pipeline pipeline, float delta) {
			pass.PushDebugGroup(scope $"Chunks - {solid ? ("Solid") : ("Transparent")}");
			pipeline.Bind(pass);
			Meteorite.INSTANCE.textures.Bind(pass, me.options.mipmaps);

			ChunkPushConstants pc = .();
			pc.projectionView = me.camera.proj * me.camera.view;

			for (Chunk chunk in visibleChunks) {
				if (chunk.mesh == null) continue;

				UpdateChunkPushConstants(pass, chunk, ref pc, delta);

				if (solid) chunk.mesh.Render(pass);
				else chunk.meshTransparent.Render(pass);
			}

			pass.PopDebugGroup();
		}

		private void RenderBlockEntities(RenderPass pass, float tickDelta) {
			pass.PushDebugGroup("Block Entities");
			me.blockEntityRenderDispatcher.Begin();

			for (Chunk chunk in visibleChunks) {
				for (BlockEntity blockEntity in chunk.BlockEntities) {
					me.blockEntityRenderDispatcher.Render(blockEntity, tickDelta);
				}
			}

			me.blockEntityRenderDispatcher.End(pass, me.camera);
			pass.PopDebugGroup();
		}

		private void RenderEntities(RenderPass pass, float tickDelta) {
			pass.PushDebugGroup("Entities");
			Gfxa.ENTITY_PIPELINE.Bind(pass);
			Gfxa.PIXEL_BIND_GRUP.Bind(pass);

			ChunkPushConstants pc = .();
			pc.projectionView = me.camera.proj * me.camera.view;
			pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &pc.projectionView);

			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass, Buffers.QUAD_INDICES);

			for (Entity entity in me.world.Entities) {
				if (entity == Meteorite.INSTANCE.player && Meteorite.INSTANCE.player.gamemode == .Spectator) continue;

				entity.Render(mb, tickDelta);
			}

			mb.Finish();

			pass.PopDebugGroup();
		}

		private void RenderBlockSelection(RenderPass pass) {
			Gfxa.LINES_PIPELINE.Bind(pass);

			Mat4 projectionView = me.camera.proj * me.camera.view;
			pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &projectionView);

			Color color = .(255, 255, 255, 100);
			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass);

			Vec3i pos = me.player.selection.blockPos;
			AABB aabb = me.world.GetBlock(pos).Shape.GetBoundingBox();
			Vec3d min = .(pos.x, pos.y, pos.z) + aabb.min;
			Vec3d max = .(pos.x, pos.y, pos.z) + aabb.max;

			uint32 ib1 = mb.Vec3(.((.) min.x, (.) min.y, (.) min.z)).Color(color).Next();
			uint32 ib2 = mb.Vec3(.((.) min.x, (.) min.y, (.) max.z)).Color(color).Next();
			uint32 ib3 = mb.Vec3(.((.) max.x, (.) min.y, (.) max.z)).Color(color).Next();
			uint32 ib4 = mb.Vec3(.((.) max.x, (.) min.y, (.) min.z)).Color(color).Next();

			uint32 it1 = mb.Vec3(.((.) min.x, (.) max.y, (.) min.z)).Color(color).Next();
			uint32 it2 = mb.Vec3(.((.) min.x, (.) max.y, (.) max.z)).Color(color).Next();
			uint32 it3 = mb.Vec3(.((.) max.x, (.) max.y, (.) max.z)).Color(color).Next();
			uint32 it4 = mb.Vec3(.((.) max.x, (.) max.y, (.) min.z)).Color(color).Next();

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

			mb.Finish();
		}

		private void RenderChunkBoundaries(RenderPass pass) {
			pass.PushDebugGroup("Chunk Boundaries");
			Gfxa.LINES_PIPELINE.Bind(pass);

			Mat4 projectionView = me.camera.proj * me.camera.view;
			pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &projectionView);

			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass);

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

			mb.Finish();

			pass.PopDebugGroup();
		}

		private void Line(MeshBuilder mb, int x, int z, Color color) {
			mb.Line(
				mb.Vec3(.(x, 0, z)).Color(color).Next(),
				mb.Vec3(.(x, me.world.height, z)).Color(color).Next()
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
				chunk.mesh.Build().Cancel();
				chunk.meshTransparent.Build().Cancel();

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