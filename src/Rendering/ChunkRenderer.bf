using System;
using System.Collections;
using System.Diagnostics;

using Cacti;

namespace Meteorite;

enum ChunkRenderLayer {
	Solid,
	Transparent
}

class ChunkRenderer : IEnumerable<Chunk> {
	private Meteorite me = .INSTANCE;
	private ThreadPool threadPool = new .();
	private List<Chunk> visibleChunks = new .() ~ delete _;

	public ~this() {
		// Deleting a thread pool will block for the currently running tasks to finish
		delete threadPool;

		// Return CPU buffers for chunks which are waiting to be uploaded
		for (Chunk chunk in me.world.Chunks) {
			ChunkData data = Data!(chunk);
			if (data.status != .Upload) continue;

			for (LayerData layerData in data.layerDatas) {
				if (!layerData.hasData) continue;

				for (Buffer buffer in layerData.buffers) {
					Buffers.Return(buffer);
				}
			}
		}
	}

	public int VisibleChunkCount => visibleChunks.Count;

	public void Setup() {
		visibleChunks.Clear();

		Vec3d cameraPos = me.camera.pos.ToFloat;

		// Frustum cull and schedule rebuilds
		for (Chunk chunk in me.world.Chunks) {
			ChunkData data = Data!(chunk);

			// Schedule rebuild
			if (chunk.dirty && (data.status == .NotReady || data.status == .Ready) && AreNeighboursLoaded(chunk)) {
				data.status = .Building;
				chunk.AddRef();

				threadPool.Add(new () => BuildChunk(chunk));
			}
			
			// Upload mesh
			if (data.status == .Upload) {
				// Calculate total buffer size
				uint64 totalSize = 0;

				for (LayerData layerData in data.layerDatas) {
					if (!layerData.hasData) continue;

					for (let buffer in layerData.buffers) {
						totalSize += buffer.Size;
					}
				}

				// Get GPU buffer
				if (data.gpuBuffer == null) {
					data.gpuBuffer = Gfx.Buffers.Create(.Vertex, .TransferDst, totalSize, scope $"Chunk {chunk.pos.x}, {chunk.pos.z}");
				}
				else {
					data.gpuBuffer.EnsureCapacity(totalSize);
				}

				// Upload data for all layers
				uint64 offset = 0;
				
				for (LayerData layerData in data.layerDatas) {
					if (!layerData.hasData) continue;

					// Upload data and set draws for this layer
					int i = 0;

					for (var buffer in ref layerData.buffers) {
						var draw = ref layerData.draws[i++];

						if (buffer.Size > 0) {
							draw.vertexOffset = (.) (offset / sizeof(BlockVertex));
							draw.indexCount = (.) (buffer.Size / (sizeof(BlockVertex) * 4) * 6);
							
							Gfx.Uploads.UploadBuffer(data.gpuBuffer.View(offset, buffer.Size), buffer.Data, buffer.Size, new [&]() => draw.valid = true);
							offset += buffer.Size;
						}
						else {
							draw.valid = false;
						}

						Buffers.Return(buffer);
						buffer = null;
					}

					layerData.hasData = false;
				}

				// Set status
				data.status = .Ready;
			}

			// Frustum cull
			if (me.camera.IsBoxVisible(chunk.min - cameraPos, chunk.max - cameraPos)) {
				visibleChunks.Add(chunk);
			}
		}

		// Sort chunks
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

	public void RenderLayer(CommandBuffer cmds, ChunkRenderLayer layer) {
		// Bind state
		cmds.PushDebugGroup(scope $"Chunks - {layer}");
		cmds.Bind(layer == .Solid ? Gfxa.CHUNK_PIPELINE : Gfxa.CHUNK_TRANSPARENT_PIPELINE);
		FrameUniforms.Bind(cmds);
		me.textures.Bind(cmds);
		me.lightmapManager.Bind(cmds, 3);

		cmds.Bind(Buffers.QUAD_INDICES);

		// Layer drawing mixin
		static mixin Draw(LayerData data, QuadCullFace cullFace) {
			Draw draw = data.draws[(.) cullFace];
			if (draw.valid) cmds.DrawIndexed(draw.indexCount, 0, draw.vertexOffset);
		}

		// Loop over all visible chunks
		Vec3d cameraPos = me.camera.pos;

		for (Chunk chunk in visibleChunks) {
			// Check if the chunks has data for this layer
			ChunkData data = Data!(chunk);
			LayerData layerData = data.GetLayerData(layer);

			if (data.gpuBuffer == null) continue;

			// Bind chunk specific state
			cmds.Bind(data.gpuBuffer);
			cmds.SetPushConstants((Vec3d(chunk.pos.x * Section.SIZE, 0, chunk.pos.z * Section.SIZE) - cameraPos).ToFloat);
			
			// Render sides
			Draw!(layerData, QuadCullFace.None);

			if (cameraPos.y > chunk.min.y) Draw!(layerData, QuadCullFace.Up);
			if (cameraPos.y < chunk.max.y) Draw!(layerData, QuadCullFace.Down);
									
			if (cameraPos.x > chunk.min.x) Draw!(layerData, QuadCullFace.East);
			if (cameraPos.x < chunk.max.x) Draw!(layerData, QuadCullFace.West);
												
			if (cameraPos.z > chunk.min.z) Draw!(layerData, QuadCullFace.South);
			if (cameraPos.z < chunk.max.z) Draw!(layerData, QuadCullFace.North);
		}

		cmds.PopDebugGroup();
	}

	private bool AreNeighboursLoaded(Chunk chunk) {
		return me.world.IsChunkLoaded(chunk.pos.x + 1, chunk.pos.z) && me.world.IsChunkLoaded(chunk.pos.x - 1, chunk.pos.z) && me.world.IsChunkLoaded(chunk.pos.x, chunk.pos.z + 1) && me.world.IsChunkLoaded(chunk.pos.x, chunk.pos.z - 1);
	}

	private void BuildChunk(Chunk chunk) {
		ChunkData data = Data!(chunk);

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

						ChunkRenderLayer layer = blockState.block == Blocks.WATER ? .Transparent : .Solid; // TODO
						
						BlockRenderer.Render(me.world, chunk, x, by, z, blockState, data.GetLayerData(layer, true).buffers);
					}
				}
			}
		}

		chunk.dirty = false;
		Data!(chunk).status = .Upload;

		// If there are no other references to the chunk apart from this one then return CPU side buffers early and do not return from the Building state
		if (chunk.ReleaseWillDelete) {
			for (LayerData layerData in Data!(chunk).layerDatas) {
				for (Buffer buffer in layerData.buffers) {
					Buffers.Return(buffer);
				}
			}

			Data!(chunk).status = .Building;
		}

		chunk.Release();
	}

	private mixin Data(Chunk chunk) {
		if (chunk.[Friend]renderData == null) {
			chunk.[Friend]renderData = new .();
		}

		chunk.[Friend]renderData
	}

	public List<Chunk>.Enumerator GetEnumerator() => visibleChunks.GetEnumerator();



	public enum Status {
		NotReady,
		Building,
		Upload,
		Ready
	}

	public struct Draw {
		public bool valid;

		public uint32 indexCount;
		public int32 vertexOffset;
	}

	public class LayerData {
		public ChunkRenderLayer layer;

		public bool hasData;
		public Buffer[Enum.GetCount<QuadCullFace>()] buffers;

		public Draw[Enum.GetCount<QuadCullFace>()] draws;
		
		public this(ChunkRenderLayer layer) {
			this.layer = layer;
		}
	}
	
	public class ChunkData {
		public Status status = .NotReady;

		public GpuBuffer gpuBuffer ~ delete _;
		public LayerData[Enum.GetCount<ChunkRenderLayer>()] layerDatas;

		public this() {
			for (let layer in Enum.GetValues<ChunkRenderLayer>()) {
				layerDatas[(.) layer] = new .(layer);
			}
		}

		public ~this() {
			for (let layerData in layerDatas) {
				delete layerData;
			}
		}

		public LayerData GetLayerData(ChunkRenderLayer layer, bool initBuffers = false) {
			LayerData data = layerDatas[(.) layer];

			if (initBuffers && !data.hasData) {
				data.hasData = true;
				for (var buffer in ref data.buffers) buffer = Buffers.Get();
			}

			return data;
		}
	}
}

extension Chunk {
	private ChunkRenderer.ChunkData renderData ~ delete _;
}