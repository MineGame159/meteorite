using System;
using System.Collections;

namespace Meteorite {
	class WorldRenderer {
		private Meteorite me = .INSTANCE;

		private ThreadPool threadPool = new .();

		private List<Chunk> visibleChunks = new .() ~ delete _;

		private Mesh meshEntities ~ delete _;
		private Mesh meshLines ~ delete _;

		public int renderedChunks;

		private bool shuttingDown;

		public ~this() {
			shuttingDown = true;

			// Thread pool needs to be deleted before ending un-uploaded meshes
			delete threadPool;

			for (Chunk chunk in me.world.Chunks) {
				if (chunk.status == .Upload) {
					chunk.mesh.End(false);
					chunk.meshTransparent.End(false);
				}
			}
		}

		public void Render(RenderPass pass, float tickDelta, float delta) {
			SetupChunks();
			
			pass.PushDebugGroup("World");

			SkyRenderer.Render(pass, me.world, me.camera, tickDelta);

			RenderChunks(pass, true, Gfxa.CHUNK_PIPELINE, delta);
			RenderEntities(pass, tickDelta);
			RenderChunks(pass, false, Gfxa.CHUNK_TRANSPARENT_PIPELINE, delta);

			if (me.options.chunkBoundaries) RenderChunkBoundaries(pass);

			pass.PopDebugGroup();
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
				}
				if (chunk.status == .Upload) {
					chunk.meshTransparent.End();
					chunk.mesh.End();
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

		private void RenderEntities(RenderPass pass, float tickDelta) {
			pass.PushDebugGroup("Entities");
			Gfxa.QUADS_PIPELINE.Bind(pass);

			ChunkPushConstants pc = .();
			pc.projectionView = me.camera.proj * me.camera.view;
			pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &pc.projectionView);

			if (meshEntities == null) meshEntities = new .(Buffers.QUAD_INDICES);
			meshEntities.Begin();

			for (Entity entity in me.world.Entities) {
				if (entity == Meteorite.INSTANCE.player && Meteorite.INSTANCE.player.gamemode == .Spectator) continue;

				entity.Render(meshEntities, tickDelta);
			}

			meshEntities.End();
			meshEntities.Render(pass);

			pass.PopDebugGroup();
		}

		private void RenderChunkBoundaries(RenderPass pass) {
			pass.PushDebugGroup("Chunk Boundaries");
			Gfxa.LINES_PIPELINE.Bind(pass);

			Mat4 projectionView = me.camera.proj * me.camera.view;
			pass.SetPushConstants(.Vertex, 0, sizeof(Mat4), &projectionView);

			if (meshLines == null) meshLines = new .();
			meshLines.Begin();

			int x = ((.) me.camera.pos.x >> 4) * 16;
			int z = ((.) me.camera.pos.z >> 4) * 16;

			Color color1 = .(225, 25, 25);
			Color color2 = .(225, 225, 25);

			Line(meshLines, x, z, color1);
			Line(meshLines, x + 16, z, color1);
			Line(meshLines, x, z + 16, color1);
			Line(meshLines, x + 16, z + 16, color1);

			x -= 16;
			z -= 16;

			Line(meshLines, x, z, color2);
			Line(meshLines, x + 48, z, color2);
			Line(meshLines, x, z + 48, color2);
			Line(meshLines, x + 48, z + 48, color2);

			Line(meshLines, x, z, color2);
			Line(meshLines, x + 16, z, color2);
			Line(meshLines, x + 32, z, color2);

			Line(meshLines, x, z, color2);
			Line(meshLines, x, z + 16, color2);
			Line(meshLines, x, z + 32, color2);

			Line(meshLines, x + 48, z, color2);
			Line(meshLines, x + 48, z + 16, color2);
			Line(meshLines, x + 48, z + 32, color2);

			Line(meshLines, x, z + 48, color2);
			Line(meshLines, x + 16, z + 48, color2);
			Line(meshLines, x + 32, z + 48, color2);

			meshLines.End();
			meshLines.Render(pass);

			pass.PopDebugGroup();
		}

		private void Line(Mesh mesh, int x, int z, Color color) {
			mesh.Line(
				mesh.Vec3(.(x, 0, z)).Color(color).Next(),
				mesh.Vec3(.(x, me.world.height, z)).Color(color).Next()
			);
		}

		private void GenerateChunkMesh(Chunk chunk) {
			chunk.mesh.Begin();
			chunk.meshTransparent.Begin();

			int minI = (.) chunk.min.y / Section.SIZE;
			int maxI = (.) chunk.max.y / Section.SIZE;

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
				chunk.mesh.End(false);
				chunk.meshTransparent.End(false);

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