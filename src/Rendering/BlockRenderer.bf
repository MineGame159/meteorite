using System;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

[CRepr]
struct BlockVertex : this(Vec3f pos, Vec2<uint16> uv, uint32 lightUv, Color color, Vec2<uint16> texture, Vec4<int8> normal) {
	public static VertexFormat FORMAT = new VertexFormat()
		.Attribute(.Float, 3)
		.Attribute(.U16, 2, true)
		.Attribute(.U16, 2, false)
		.Attribute(.U8, 4, true)
		.Attribute(.U16, 2)
		.Attribute(.I8, 4, true)
		 ~ delete _;
}

static class BlockRenderer {
	public const uint32 FULL_BRIGHT_UV = 0xF000F0;

	// Main
	
	public static void Render(World world, Chunk chunk, Vec3i pos, BlockState blockState, Buffer[Enum.GetCount<QuadCullFace>()] buffers) {
		if (blockState.model == null) return;

		Context ctx = scope .(world, chunk, pos, blockState);

		// Fluids
		if (blockState.block == Blocks.WATER || blockState.block == Blocks.LAVA) {
			RenderFluid(ctx, buffers);
			return;
		}
		else if (IsFilledWithWater(blockState)) {
			ctx.BlockState = Blocks.WATER.defaultBlockState;

			RenderFluid(ctx, buffers);

			ctx.BlockState = blockState;
			ctx.ResetBlockColors();
		}

		// Solid blocks
		Vec3f renderPos = (.) pos + blockState.GetOffset(pos.x, pos.z);

		bool calculatedFullTint = false;
		Color fullTint = .ZERO;

		for (Quad quad in blockState.model.quads) {
			// Cull
			if (!ShouldRender(ctx, quad)) continue;

			// Tint
			if (quad.tint) {
				ctx.CalculateBlockColors();
	
				// If this is a non full-block then do a single 27-block average instead of calculating the average per-vertex
				if (!blockState.model.fullBlock && !calculatedFullTint) {
					fullTint = Tint(ctx, quad, 0, true);
					calculatedFullTint = true;
				}
			}

			// Light
			uint32 lightUv = GetLightmapUv(ctx, quad);

			// Ambient Occlusion
			Vec4f ao = GetAO(ctx, quad);

			// Normal
			Vec3f d0 = quad.vertices[2].pos - quad.vertices[0].pos;
			Vec3f d1 = quad.vertices[3].pos - quad.vertices[1].pos;

			Vec3f normal = .(d1.y * d0.z - d1.z * d0.y, d1.z * d0.x - d1.x * d0.z, d1.x * d0.y - d1.y * d0.x);

			float l = Math.Sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z);
			if (l != 0) normal /= l;

			normal *= 127;

			// Emit quad
			Buffer buffer = buffers[(.) quad.cullFace];
			buffer.EnsureCapacity<BlockVertex>(4);

			Color color = .WHITE;
			bool tint = quad.tint;
			
			if (tint && !blockState.model.fullBlock) {
				color = fullTint;
				tint = false;
			}

			if (tint) color = Tint(ctx, quad, 0);
			Vertex(buffer, renderPos, quad.vertices[0], quad.texture, lightUv, color.MulWithoutA(quad.light * ao.x), normal);

			if (tint) color = Tint(ctx, quad, 1);
			Vertex(buffer, renderPos, quad.vertices[1], quad.texture, lightUv, color.MulWithoutA(quad.light * ao.y), normal);

			if (tint) color = Tint(ctx, quad, 2);
			Vertex(buffer, renderPos, quad.vertices[2], quad.texture, lightUv, color.MulWithoutA(quad.light * ao.z), normal);

			if (tint) color = Tint(ctx, quad, 3);
			Vertex(buffer, renderPos, quad.vertices[3], quad.texture, lightUv, color.MulWithoutA(quad.light * ao.w), normal);
		}
	}

	// Fluid rendering

	private static bool IsFilledWithWater(BlockState blockState) {
		Block block = blockState.block;
		return block == Blocks.SEAGRASS || block == Blocks.TALL_SEAGRASS || block == Blocks.KELP || block == Blocks.KELP_PLANT;
	}

	private static void RenderFluid(Context ctx, Buffer[Enum.GetCount<QuadCullFace>()] buffers) {
		// Cull
		BlockState above = ctx.GetBlockState(.Up);
		if (above.block == Blocks.WATER || above.block == Blocks.LAVA || IsFilledWithWater(above)) return;

		Quad quad = ctx.BlockState.model.quads[0];
		Vec3f renderPos = (.) ctx.pos;

		// Y Offset
		Property p = ctx.BlockState.GetProperty("level");
		float yOffset = (p.value == 0 ? 15 : 15 - p.value) / 16f;

		// Light
		uint32 lightUv = GetLightmapUv(ctx, quad);

		// Normal
		Vec3f normal = .(0, 127, 0);

		// Emit quad
		Buffer buffer = buffers[(.) QuadCullFace.Up];
		buffer.EnsureCapacity<BlockVertex>(4);

		Color color = .WHITE;
		bool tint = false;

		if (ctx.BlockState.block == Blocks.WATER) {
			ctx.CalculateBlockColors();
			tint = true;
		}

		if (tint) color = Tint(ctx, quad, 0);
		Vertex(buffer, renderPos, .(.(0, yOffset, 0), quad.vertices[0].uv), quad.texture, lightUv, color, normal);

		if (tint) color = Tint(ctx, quad, 1);
		Vertex(buffer, renderPos, .(.(1, yOffset, 0), quad.vertices[1].uv), quad.texture, lightUv, color, normal);

		if (tint) color = Tint(ctx, quad, 2);
		Vertex(buffer, renderPos, .(.(1, yOffset, 1), quad.vertices[2].uv), quad.texture, lightUv, color, normal);

		if (tint) color = Tint(ctx, quad, 3);
		Vertex(buffer, renderPos, .(.(0, yOffset, 1), quad.vertices[3].uv), quad.texture, lightUv, color, normal);
	}

	// Culling

	private static bool ShouldRender(Context ctx, Quad quad) {
		// Only try to cull faces that are touching the block boundary
		if (!quad.adjacent) return true;

		// Do not render quads facing the void
		if (ctx.pos.y < 0 || ctx.pos.y + quad.direction.GetOffset().y < 0) return false;

		// Force render quads facing up when in the top layer
		if (ctx.pos.y >= Section.SIZE * ctx.world.SectionCount) return true;

		// Get adjacent block state
		BlockState blockState = ctx.GetBlockState(quad.direction);

		// Force render if the adjacent block is transparent
		if (blockState.block.transparent) return true;

		// Do not render if the adjacent block is a full block
		if (blockState.model.fullBlock) return false;

		// Test every quad for visibility
		for (Quad otherQuad in blockState.model.GetAdjacentQuads(quad.direction.GetOpposite())) {
			if (TestQuads!(quad, otherQuad.min, otherQuad.max)) return false;
		}

		return true;
	}

	private static mixin TestQuads(Quad quad, Vec3f min, Vec3f max) {
		bool culled = false;

		switch (quad.direction) {
		case .Up, .Down:     if (quad.min.x >= min.x && quad.max.x <= max.x && quad.min.z >= min.z && quad.max.z <= max.z) culled = true;
		case .East, .West:   if (quad.min.y >= min.y && quad.max.y <= max.y && quad.min.z >= min.z && quad.max.z <= max.z) culled = true;
		case .North, .South: if (quad.min.x >= min.x && quad.max.x <= max.x && quad.min.y >= min.y && quad.max.y <= max.y) culled = true;
		}

		culled
	}

	// Lighting

	private static uint32 GetLightmapUv(Context ctx, Quad quad) {
		if (quad.adjacent) {
			let (chunk, pos) = ctx.GetChunkWithPos(ctx.pos + quad.direction.GetOffset());
			if (chunk == null) return 0;

			return GetLightmapUvImpl(chunk, ctx.BlockState, pos);
		}
		
		return GetLightmapUvImpl(ctx.chunk, ctx.BlockState, ctx.pos);
	}

	private static uint32 GetLightmapUvImpl(Chunk chunk, BlockState blockState, Vec3i pos) {
		if (blockState.emissive) return FULL_BRIGHT_UV;

		uint32 sky = (.) chunk.GetLight(.Sky, pos.x, pos.y, pos.z);
		uint32 block = (.) chunk.GetLight(.Block, pos.x, pos.y, pos.z);
		
		if (block < blockState.luminance) block = blockState.luminance;

		return PackLightmapUv(sky, block);
	}
	
	[Optimize, Inline]
	public static uint32 PackLightmapUv(uint32 sky, uint32 block) => sky << 20 | block << 4;

	// Tinting

	private static Color Tint(Context ctx, Quad quad, int vertexIndex, bool full = false) {
		Color Average(Vec3i min, Vec3i max) {
			int r = 0;
			int g = 0;
			int b = 0;

			int count = 0;
	
			for (int x = min.x; x <= max.x; x++) {
				for (int y = min.y; y <= max.y; y++) {
					for (int z = min.z; z <= max.z; z++) {
						Color color = ctx.GetBlockColor(.(x, y, z));
	
						r += color.r;
						g += color.g;
						b += color.b;

						count++;
					}
				}
			}
	
			return .(
				(uint8) (r / count),
				(uint8) (g / count),
				(uint8) (b / count),
				255
			);
		}

		if (full) {
			return Average(.NEG_ONE, .ONE);
		}

		// Calculate snapped vertex position, the reason to snap positions to 0 and 1 if between some threshold is to have per-vertex smooth colors on blocks such as water
		Vec3f vertexPos = quad.vertices[vertexIndex].pos;

		if (vertexPos.x <= 0.2) vertexPos.x = 0;
		else if (vertexPos.x >= 0.8) vertexPos.x = 1;

		if (vertexPos.y <= 0.2) vertexPos.y = 0;
		else if (vertexPos.y >= 0.8) vertexPos.y = 1;

		if (vertexPos.z <= 0.2) vertexPos.z = 0;
		else if (vertexPos.z >= 0.8) vertexPos.z = 1;

		// Calculate average
		switch (vertexPos) {
		case .(0, 0, 0):	return Average(.(-1, -1, -1), .( 0,  0,  0));
		case .(1, 0, 0):	return Average(.( 0, -1, -1), .( 1,  0,  0));
		case .(0, 0, 1):	return Average(.(-1, -1,  0), .( 0,  0,  1));
		case .(1, 0, 1):	return Average(.( 0, -1,  0), .( 1,  0,  1));
			
		case .(0, 1, 0):	return Average(.(-1,  0, -1), .( 0,  1,  0));
		case .(1, 1, 0):	return Average(.( 0,  0, -1), .( 1,  1,  0));
		case .(0, 1, 1):	return Average(.(-1,  0,  0), .( 0,  1,  1));
		case .(1, 1, 1):	return Average(.( 0,  0,  0), .( 1,  1,  1));

		default:			return Average(.NEG_ONE, .ONE);
		}
	}

	// Ambient Occlusion

	private static Vec4f GetAO(Context ctx, Quad quad) {
		if (!Meteorite.INSTANCE.options.ao.HasVanilla || !ctx.BlockState.model.fullBlock) return .ONE;

		float ao1 = 1;
		float ao2 = 1;
		float ao3 = 1;
		float ao4 = 1;

	    switch (quad.direction) {
	    case .Up:
	        ao1 = AoY(ctx, (.) quad.vertices[0].pos.x, 1, (.) quad.vertices[0].pos.z);
	        ao2 = AoY(ctx, (.) quad.vertices[1].pos.x, 1, (.) quad.vertices[1].pos.z);
	        ao3 = AoY(ctx, (.) quad.vertices[2].pos.x, 1, (.) quad.vertices[2].pos.z);
	        ao4 = AoY(ctx, (.) quad.vertices[3].pos.x, 1, (.) quad.vertices[3].pos.z);
	    case .Down:
	        ao1 = AoY(ctx, (.) quad.vertices[0].pos.x, 0, (.) quad.vertices[0].pos.z);
	        ao2 = AoY(ctx, (.) quad.vertices[1].pos.x, 0, (.) quad.vertices[1].pos.z);
	        ao3 = AoY(ctx, (.) quad.vertices[2].pos.x, 0, (.) quad.vertices[2].pos.z);
	        ao4 = AoY(ctx, (.) quad.vertices[3].pos.x, 0, (.) quad.vertices[3].pos.z);
	    case .East:
	        ao1 = AoX(ctx, 1, (.) quad.vertices[0].pos.y, (.) quad.vertices[0].pos.z);
	        ao2 = AoX(ctx, 1, (.) quad.vertices[1].pos.y, (.) quad.vertices[1].pos.z);
	        ao3 = AoX(ctx, 1, (.) quad.vertices[2].pos.y, (.) quad.vertices[2].pos.z);
	        ao4 = AoX(ctx, 1, (.) quad.vertices[3].pos.y, (.) quad.vertices[3].pos.z);
	    case .West:
	        ao1 = AoX(ctx, 0, (.) quad.vertices[0].pos.y, (.) quad.vertices[0].pos.z);
	        ao2 = AoX(ctx, 0, (.) quad.vertices[1].pos.y, (.) quad.vertices[1].pos.z);
	        ao3 = AoX(ctx, 0, (.) quad.vertices[2].pos.y, (.) quad.vertices[2].pos.z);
	        ao4 = AoX(ctx, 0, (.) quad.vertices[3].pos.y, (.) quad.vertices[3].pos.z);
	    case .North:
	        ao1 = AoZ(ctx, (.) quad.vertices[0].pos.x, (.) quad.vertices[0].pos.y, 0);
	        ao2 = AoZ(ctx, (.) quad.vertices[1].pos.x, (.) quad.vertices[1].pos.y, 0);
	        ao3 = AoZ(ctx, (.) quad.vertices[2].pos.x, (.) quad.vertices[2].pos.y, 0);
	        ao4 = AoZ(ctx, (.) quad.vertices[3].pos.x, (.) quad.vertices[3].pos.y, 0);
	    case .South:
	        ao1 = AoZ(ctx, (.) quad.vertices[0].pos.x, (.) quad.vertices[0].pos.y, 1);
	        ao2 = AoZ(ctx, (.) quad.vertices[1].pos.x, (.) quad.vertices[1].pos.y, 1);
	        ao3 = AoZ(ctx, (.) quad.vertices[2].pos.x, (.) quad.vertices[2].pos.y, 1);
	        ao4 = AoZ(ctx, (.) quad.vertices[3].pos.x, (.) quad.vertices[3].pos.y, 1);
		default:
	    }

		return .(
			ao1 / 2.0f + 0.5f,
			ao2 / 2.0f + 0.5f,
			ao3 / 2.0f + 0.5f,
			ao4 / 2.0f + 0.5f
		);
	}

	private static float AoY(Context ctx, int vx, int vy, int vz) {
		var vx, vy, vz;

	    if (vx == 0) vx = -1;
	    if (vy == 0) vy = -1;
	    if (vz == 0) vz = -1;

	    return Idk(CanOcclude(ctx, vx, vy, 0), CanOcclude(ctx, 0, vy, vz), CanOcclude(ctx, vx, vy, vz)) / 3.0f;
	}

	private static float AoX(Context ctx, int vx, int vy, int vz) {
		var vx, vy, vz;

	    if (vx == 0) vx = -1;
	    if (vy == 0) vy = -1;
	    if (vz == 0) vz = -1;

	    return Idk(CanOcclude(ctx, vx, vy, 0), CanOcclude(ctx, vx, 0, vz), CanOcclude(ctx, vx, vy, vz)) / 3.0f;
	}

	private static float AoZ(Context ctx, int vx, int vy, int vz) {
		var vx, vy, vz;
		
	    if (vx == 0) vx = -1;
	    if (vy == 0) vy = -1;
	    if (vz == 0) vz = -1;

	    return Idk(CanOcclude(ctx, vx, 0, vz), CanOcclude(ctx, 0, vy, vz), CanOcclude(ctx, vx, vy, vz)) / 3.0f;
	}
	
	[Optimize, Inline]
	private static bool CanOcclude(Context ctx, int offsetX, int offsetY, int offsetZ) {
		Model model = ctx.GetBlockState(Vec3i(offsetX, offsetY, offsetZ)).model;
	    return model != null && model.fullBlock;
	}
	
	[Optimize, Inline]
	private static int Idk(bool side1, bool side2, bool corner) {
	    if (side1 && side2) return 0;
	    return 3 - ((side1 ? 1 : 0) + (side2 ? 1 : 0) + (corner ? 1 : 0));
	}

	// Other

	[Optimize, Inline]
	private static void Vertex(Buffer buffer, Vec3f pos, Vertex v, uint16 texture, uint32 lightUv, Color color, Vec3f normal) {
		buffer.Add(BlockVertex(
			pos + v.pos,
			v.uv,
			lightUv,
			color,
			.(texture, 0),
			.((.) normal.x, (.) normal.y, (.) normal.z, 0)
		));
	}

	// Context

	class Context {
		public World world;
		public Chunk chunk;

		public Vec3i pos;

		private BlockState[7] blockStates;

		private bool queriedBiome;
		private Biome biome;

		private Color[27] blockColors;
		private bool calculatedBlockColors;

		public this(World world, Chunk chunk, Vec3i pos, BlockState blockState) {
			this.world = world;
			this.chunk = chunk;
			
			this.pos = pos;

			this.blockStates[0] = blockState;
		}

		// Chunk

		public (Chunk chunk, Vec3i pos) GetChunkWithPos(Vec3i pos) {
			if (pos.x >= 0 && pos.x < Section.SIZE && pos.z >= 0 && pos.z < Section.SIZE) return (chunk, pos);

			int bx = chunk.pos.x * Section.SIZE + pos.x;
			int bz = chunk.pos.z * Section.SIZE + pos.z;

			Chunk chunk = world.GetChunk(bx >> 4, bz >> 4);
			return (chunk, .(bx & 15, pos.y, bz & 15));
		}

		// Block

		public BlockState BlockState {
			get => blockStates[0];
			set => blockStates[0] = value;
		}

		public BlockState GetBlockState(Direction direction) {
			var blockState = ref blockStates[1 + (.) direction];
			
			if (blockState == null) {
				blockState = GetBlockStateImpl(direction.GetOffset());
			}

			return blockState;
		}

		public BlockState GetBlockState(Vec3i offset) {
			/*switch (offset) {
			case .( 0,  1,  0):	return GetBlockState(.Up);
			case .( 0, -1,  0):	return GetBlockState(.Down);
			case .( 1,  0,  0):	return GetBlockState(.East);
			case .(-1,  0,  0):	return GetBlockState(.West);
			case .( 0,  0,  1):	return GetBlockState(.South);
			case .( 0,  0, -1):	return GetBlockState(.North);
			default:			return GetBlockStateImpl(offset);
			}*/

			return GetBlockStateImpl(offset);
		}

		private BlockState GetBlockStateImpl(Vec3i offset) {
			Vec3i pos = this.pos + offset;

			if (pos.y < 0 || pos.y >= world.dimension.height) return Blocks.AIR.defaultBlockState;

			(let chunk, pos) = GetChunkWithPos(pos);
			if (chunk == null) return Blocks.AIR.defaultBlockState;

			return chunk.Get(pos.x, pos.y, pos.z);
		}

		// Biome

		public Biome Biome { get {
			if (!queriedBiome) {
				biome = GetBiomeImpl(.ZERO);
				queriedBiome = true;
			}

			return biome;
		} }

		public Biome GetBiome(Vec3i offset) {
			if (offset.IsZero) return Biome;

			return GetBiomeImpl(offset);
		}

		private Biome GetBiomeImpl(Vec3i offset) {
			Vec3i pos = this.pos + offset;

			if (pos.y < 0 || pos.y >= world.dimension.height) return null;

			(let chunk, pos) = GetChunkWithPos(pos);
			return chunk?.GetBiome(pos.x, pos.y, pos.z);
		}

		// Block colors

		public void CalculateBlockColors() {
			if (calculatedBlockColors) return;
			calculatedBlockColors = true;

			for (int x = -1; x <= 1; x++) {
				for (int y = -1; y <= 1; y++) {
					for (int z = -1; z <= 1; z++) {
						Vec3i offset = .(x, y, z);
						Biome biome = GetBiome(offset);

						if (biome != null) {
							blockColors[BlockColorIndex!(offset)] = BlockColors.Get(BlockState, biome);
						}
					}
				}
			}
		}

		public void ResetBlockColors() => calculatedBlockColors = false;
		
		public Color GetBlockColor(Vec3i offset) => blockColors[BlockColorIndex!(offset)];

		private static mixin BlockColorIndex(Vec3i offset) {
			int x = offset.x + 1;
			int y = (offset.y + 1) * 3;
			int z = (offset.z + 1) * 3 * 3;
			
			x + y + z
		}
	}
}