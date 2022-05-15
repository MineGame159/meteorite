using System;
using System.Collections;

namespace Meteorite {
	class World {
		private Dictionary<ChunkPos, Chunk> chunks ~ DeleteDictionaryAndValues!(_);
		private List<Chunk> b = new .() ~ delete _;

		private Dictionary<int, Entity> entities = new .() ~ DeleteDictionaryAndValues!(_);

		private static VertexFormat FORMAT = new .(.(.Float, 3), .(.Float, 2), .(.UByte, 4, true)) ~ delete _;
		private static VertexFormat FORMAT_ENTITIES = new .(.(.Float, 3), .(.UByte, 4, true)) ~ delete _;

		private Mesh meshEntities ~ delete _;
		private Mesh meshLines ~ delete _;

		private ThreadExecutor chunkBuilderThread ~ delete _;

		public int minY, height;
		public int renderedChunks;

		public this(int minY, int height) {
			this.chunks = new Dictionary<ChunkPos, Chunk>();
			this.chunkBuilderThread = new .("Chunk Builder");
			this.minY = minY;
			this.height = height;
		}

		public int SectionCount => height / Section.SIZE;
		public int ChunkCount => chunks.Count;
		public int EntityCount => entities.Count;

		public void AddChunk(Chunk chunk) {
			ChunkPos p;
			Chunk c;
			if (chunks.TryGet(chunk.pos, out p, out c)) delete c;

			chunks[chunk.pos] = chunk;
		}

		public Chunk GetChunk(int x, int z) {
			return chunks.GetValueOrDefault(.(x, z));
		}

		public bool IsChunkLoaded(int x, int z) {
			return chunks.ContainsKey(.(x, z));
		}

		public void ReloadChunks() {
			for (Chunk chunk in chunks.Values) chunk.dirty = true;
		}

		public void AddEntity(Entity entity) {
			entities[entity.id] = entity;
		}

		public void RemoveEntity(int entityId) {
			if (entities.GetAndRemove(entityId) case .Ok(let val)) delete val.value;
		}

		public Entity GetEntity(int entityId) {
			return entities.GetValueOrDefault(entityId);
		}

		public void Tick() {
			for (Entity entity in entities.Values) entity.Tick();
		}

		public void Render(Camera camera, double tickDelta, bool mipmaps) {
			Gfx.PushDebugGroup("World");

			// Chunks solid
			ChunkPushConstants pc = .();
			pc.projectionView = camera.proj * camera.view;

			Gfx.PushDebugGroup("Chunks - Solid");
			Gfxa.CHUNK_PIPELINE.Bind();

			if (mipmaps) Gfxa.CHUNK_MIPMAP_BIND_GROUP.Bind();
			else Gfxa.CHUNK_BIND_GROUP.Bind();

			renderedChunks = 0;
			int a = 0;

			b.Clear();

			for (Chunk chunk in chunks.Values) {
				if (chunk.dirty && chunk.status == .Ready && chunkBuilderThread.TaskCount < 2 && a < 8 && IsChunkLoaded(chunk.pos.x + 1, chunk.pos.z) && IsChunkLoaded(chunk.pos.x - 1, chunk.pos.z) && IsChunkLoaded(chunk.pos.x, chunk.pos.z + 1) && IsChunkLoaded(chunk.pos.x, chunk.pos.z - 1)) {
					chunk.status = .Building;
					if (chunk.mesh == null) {
						chunk.mesh = new Mesh(Buffers.QUAD_INDICES);
						chunk.meshTransparent = new Mesh(Buffers.QUAD_INDICES);
					}
					chunk.mesh.Begin();
					chunk.meshTransparent.Begin();
					//chunkBuilderThread.Add(new () => GenerateChunkMesh(chunk));
					System.Threading.ThreadPool.QueueUserWorkItem(new () => GenerateChunkMesh(chunk));
					//GenerateChunkMesh(chunk);
					a++;
				}
				/*else */if (chunk.status == .Upload) {
					chunk.meshTransparent.End();
					chunk.mesh.End();
					chunk.status = .Ready;
				}

				if (chunk.status == .Ready && camera.IsBoxVisible(chunk.min, chunk.max)) {
					if (chunk.mesh != null) {
						pc.chunkPos = .(chunk.pos.x * Section.SIZE, chunk.pos.z * Section.SIZE);
						Gfx.SetPushConstants(.Vertex, 0, sizeof(ChunkPushConstants), &pc);
						chunk.mesh.Render();
					}

					renderedChunks++;
					b.Add(chunk);
				}
			}

			Gfx.PopDebugGroup();

			// Entities
			Gfx.PushDebugGroup("Entities");
			Gfxa.QUADS_PIPELINE.Bind();
			Gfx.SetPushConstants(.Vertex, 0, sizeof(Mat4), &pc.projectionView);

			if (meshEntities == null) meshEntities = new .(Buffers.QUAD_INDICES);
			meshEntities.Begin();

			for (Entity entity in entities.Values) {
				entity.Render(meshEntities, tickDelta);
			}

			meshEntities.End();
			meshEntities.Render();

			Gfx.PopDebugGroup();

			// Chunks transparent
			Gfx.PushDebugGroup("Chunks - Transparent");
			Gfxa.CHUNK_TRANSPARENT_PIPELINE.Bind();

			for (Chunk chunk in b) {
				if (chunk.meshTransparent == null) continue;

				pc.chunkPos = .(chunk.pos.x * Section.SIZE, chunk.pos.z * Section.SIZE);
				Gfx.SetPushConstants(.Vertex, 0, sizeof(ChunkPushConstants), &pc);
				chunk.meshTransparent.Render();
			}

			Gfx.PopDebugGroup();
			Gfx.PopDebugGroup();
		}

		public void RenderChunkBoundaries(Camera camera) {
			Gfx.PushDebugGroup("Chunk Boundaries");
			Gfxa.LINES_PIPELINE.Bind();

			Mat4 projectionView = camera.proj * camera.view;
			Gfx.SetPushConstants(.Vertex, 0, sizeof(Mat4), &projectionView);

			if (meshLines == null) meshLines = new .();
			meshLines.Begin();

			int x = ((.) camera.pos.x >> 4) * 16;
			int z = ((.) camera.pos.z >> 4) * 16;

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
			meshLines.Render();

			Gfx.PopDebugGroup();
		}

		private void Line(Mesh mesh, int x, int z, Color color) {
			mesh.Line(
				mesh.Vec3(.(x, 0, z)).Color(color).Next(),
				mesh.Vec3(.(x, height, z)).Color(color).Next()
			);
		}

		private void GenerateChunkMesh(Chunk chunk) {
			for (int i < SectionCount) {
				Section section = chunk.GetSection(i);
				if (section == null) continue;

				int sectionY = i * Section.SIZE;

				for (int x < Section.SIZE) {
					for (int y < Section.SIZE) {
						for (int z < Section.SIZE) {
							int by = sectionY + y;
							int sy = y % Section.SIZE;
							BlockState blockState = section.Get(x, sy, z);

							BlockRenderer.Render(this, chunk, x, by, z, blockState, section.GetBiome(x, sy, z));
						}
					}
				}
			}

			chunk.status = .Upload;
			chunk.dirty = false;
		}
	}
}