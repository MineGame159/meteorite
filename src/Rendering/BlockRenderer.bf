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

	private static bool IsFilledWithWater(Block block) {
		return block == Blocks.SEAGRASS || block == Blocks.TALL_SEAGRASS || block == Blocks.KELP || block == Blocks.KELP_PLANT;
	}
	
	private static void RenderFluid(World world, Chunk chunk, int x, int y, int z, BlockState blockState, Buffer[Enum.GetCount<QuadCullFace>()] buffers) {
		Block b = chunk.Get(x, y + 1, z).block;
		if (b == Blocks.WATER || b == Blocks.LAVA || IsFilledWithWater(b)) return;

		Quad quad = blockState.model.quads[0];

		Color c = .(255, 255, 255);
		if (blockState.block == Blocks.WATER) Tint(chunk, blockState, x, y, z, ref c);
		c.a = 255;

		Property p = blockState.GetProperty("level");
		float yOffset = (p.value == 0 ? 15 : 15 - p.value) / 16f;

		Vec3f normal = .(0, 127, 0);
		Vec3f offset = .ZERO;

		uint32 lightUv = GetLightmapUv(world, chunk, blockState, x, y, z, quad);

		Buffer buffer = buffers[(.) QuadCullFace.Up];
		buffer.EnsureCapacity<BlockVertex>(4);

		Vertex!(buffer, x, y, z, Vertex(.(0, yOffset, 0), quad.vertices[0].uv), offset, quad.texture, lightUv, c, normal);
		Vertex!(buffer, x, y, z, Vertex(.(1, yOffset, 0), quad.vertices[1].uv), offset, quad.texture, lightUv, c, normal);
		Vertex!(buffer, x, y, z, Vertex(.(1, yOffset, 1), quad.vertices[2].uv), offset, quad.texture, lightUv, c, normal);
		Vertex!(buffer, x, y, z, Vertex(.(0, yOffset, 1), quad.vertices[3].uv), offset, quad.texture, lightUv, c, normal);
	}
	
	public static void Render(World world, Chunk chunk, int x, int y, int z, BlockState blockState, Buffer[Enum.GetCount<QuadCullFace>()] buffers) {
		if (blockState.model == null) return;

		if (blockState.block == Blocks.WATER || blockState.block == Blocks.LAVA) {
			RenderFluid(world, chunk, x, y, z, blockState, buffers);
			return;
		}
		else if (IsFilledWithWater(blockState.block)) RenderFluid(world, chunk, x, y, z, Blocks.WATER.defaultBlockState, buffers);

		Vec3f offset = blockState.GetOffset(x, z);

		Foo foo = .(world, chunk, x, y, z);
		bool ao = Meteorite.INSTANCE.options.ao.HasVanilla;

		for (Quad quad in blockState.model.quads) {
			// Cull
			if (quad.adjacent) {
				if (!ShouldRender(ref foo, quad, quad.direction)) continue;
			}

			// AO
			float ao1 = 1;
			float ao2 = 1;
			float ao3 = 1;
			float ao4 = 1;

			if (ao && blockState.model.fullBlock) {
			    switch (quad.direction) {
		        case .Up:
		            ao1 = AoY(world, chunk, x, y, z, (.) quad.vertices[0].pos.x, 1, (.) quad.vertices[0].pos.z);
		            ao2 = AoY(world, chunk, x, y, z, (.) quad.vertices[1].pos.x, 1, (.) quad.vertices[1].pos.z);
		            ao3 = AoY(world, chunk, x, y, z, (.) quad.vertices[2].pos.x, 1, (.) quad.vertices[2].pos.z);
		            ao4 = AoY(world, chunk, x, y, z, (.) quad.vertices[3].pos.x, 1, (.) quad.vertices[3].pos.z);
		        case .Down:
		            ao1 = AoY(world, chunk, x, y, z, (.) quad.vertices[0].pos.x, 0, (.) quad.vertices[0].pos.z);
		            ao2 = AoY(world, chunk, x, y, z, (.) quad.vertices[1].pos.x, 0, (.) quad.vertices[1].pos.z);
		            ao3 = AoY(world, chunk, x, y, z, (.) quad.vertices[2].pos.x, 0, (.) quad.vertices[2].pos.z);
		            ao4 = AoY(world, chunk, x, y, z, (.) quad.vertices[3].pos.x, 0, (.) quad.vertices[3].pos.z);
		        case .East:
		            ao1 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[0].pos.y, (.) quad.vertices[0].pos.z);
		            ao2 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[1].pos.y, (.) quad.vertices[1].pos.z);
		            ao3 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[2].pos.y, (.) quad.vertices[2].pos.z);
		            ao4 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[3].pos.y, (.) quad.vertices[3].pos.z);
		        case .West:
		            ao1 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[0].pos.y, (.) quad.vertices[0].pos.z);
		            ao2 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[1].pos.y, (.) quad.vertices[1].pos.z);
		            ao3 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[2].pos.y, (.) quad.vertices[2].pos.z);
		            ao4 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[3].pos.y, (.) quad.vertices[3].pos.z);
		        case .North:
		            ao1 = AoZ(world, chunk, x, y, z, (.) quad.vertices[0].pos.x, (.) quad.vertices[0].pos.y, 0);
		            ao2 = AoZ(world, chunk, x, y, z, (.) quad.vertices[1].pos.x, (.) quad.vertices[1].pos.y, 0);
		            ao3 = AoZ(world, chunk, x, y, z, (.) quad.vertices[2].pos.x, (.) quad.vertices[2].pos.y, 0);
		            ao4 = AoZ(world, chunk, x, y, z, (.) quad.vertices[3].pos.x, (.) quad.vertices[3].pos.y, 0);
		        case .South:
		            ao1 = AoZ(world, chunk, x, y, z, (.) quad.vertices[0].pos.x, (.) quad.vertices[0].pos.y, 1);
		            ao2 = AoZ(world, chunk, x, y, z, (.) quad.vertices[1].pos.x, (.) quad.vertices[1].pos.y, 1);
		            ao3 = AoZ(world, chunk, x, y, z, (.) quad.vertices[2].pos.x, (.) quad.vertices[2].pos.y, 1);
		            ao4 = AoZ(world, chunk, x, y, z, (.) quad.vertices[3].pos.x, (.) quad.vertices[3].pos.y, 1);
				default:
		        }
			}

		    ao1 = ao1 / 2.0f + 0.5f;
		    ao2 = ao2 / 2.0f + 0.5f;
		    ao3 = ao3 / 2.0f + 0.5f;
		    ao4 = ao4 / 2.0f + 0.5f;

			// Light
			uint32 lightUv = GetLightmapUv(world, chunk, blockState, x, y, z, quad);

			// Tint
			Color c = .(255, 255, 255);
			if (quad.tint) Tint(chunk, blockState, x, y, z, ref c);

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

			Vertex!(buffer, x, y, z, quad.vertices[0], offset, quad.texture, lightUv, c.MulWithoutA(quad.light * ao1), normal);
			Vertex!(buffer, x, y, z, quad.vertices[1], offset, quad.texture, lightUv, c.MulWithoutA(quad.light * ao2), normal);
			Vertex!(buffer, x, y, z, quad.vertices[2], offset, quad.texture, lightUv, c.MulWithoutA(quad.light * ao3), normal);
			Vertex!(buffer, x, y, z, quad.vertices[3], offset, quad.texture, lightUv, c.MulWithoutA(quad.light * ao4), normal);
		}
	}

	private static mixin Vertex(Buffer buffer, int x, int y, int z, Vertex v, Vec3f offset, uint16 texture, uint32 lightUv, Color color, Vec3f normal) {
		buffer.Add(BlockVertex(
			.(x + v.pos.x + offset.x, y + v.pos.y + offset.y, z + v.pos.z + offset.z),
			v.uv,
			lightUv,
			color,
			.(texture, 0),
			.((.) normal.x, (.) normal.y, (.) normal.z, 0)
		));
	}

	private static void Tint(Chunk chunk, BlockState blockState, int x, int y, int z, ref Color color) {
		int r = 0;
		int g = 0;
		int b = 0;

		int s = 1;

		int count = 0;
		for (int x1 = x - s; x1 <= x + s; x1++) {
			for (int y1 = y - s; y1 <= y + s; y1++) {
			    for (int z1 = z - s; z1 <= z + s; z1++) {
					Biome bi = GetBiome(chunk, x1, y1, z1);
					if (bi == null) continue;

					Color co = BlockColors.Get(blockState, bi);
					r += co.r;
					g += co.g;
					b += co.b;

					count++;
				}
			}
		}

		color.r = (.) (r / count);
		color.g = (.) (g / count);
		color.b = (.) (b / count);
	}
	
	private static Biome GetBiome(Chunk chunk, int x, int y, int z) {
		World world = chunk.world;

		if (y < 0 || y >= world.dimension.height) return null;
		if (x >= 0 && x < Section.SIZE && z >= 0 && z < Section.SIZE) return chunk.GetBiome(x, y, z);

		int bx = chunk.pos.x * Section.SIZE + x;
		int bz = chunk.pos.z * Section.SIZE + z;

		Chunk c = world.GetChunk(bx >> 4, bz >> 4);
		if (c == null) return null;

		return c.GetBiome(x, y, z);
	}
	
	private static BlockState GetBlock(World world, Chunk chunk, int x, int y, int z) {
		if (y < 0) return Blocks.AIR.defaultBlockState;
		if (y >= Section.SIZE * 16) return Blocks.AIR.defaultBlockState;
		if (x >= 0 && x < Section.SIZE && z >= 0 && z < Section.SIZE) return chunk.Get(x, y, z);

		int bx = chunk.pos.x * Section.SIZE + x;
		int bz = chunk.pos.z * Section.SIZE + z;

		Chunk c = world.GetChunk(bx >> 4, bz >> 4);
		if (c == null) return Blocks.AIR.defaultBlockState;

		return c.Get(bx & 15, y, bz & 15);
	}

	private static uint32 GetLightmapUv(World world, Chunk chunk, BlockState blockState, int x, int y, int z, Quad quad) {
		if (quad.adjacent) {
			Vec3i offset = quad.direction.GetOffset();
			return GetLightmapUv(world, chunk, blockState, x + offset.x, y + offset.y, z + offset.z);
		}

		return GetLightmapUv(world, chunk, blockState, x, y, z);
	}

	private static uint32 GetLightmapUv(World world, Chunk chunk, BlockState blockState, int x, int y, int z) {
	    if (blockState.emissive) return FULL_BRIGHT_UV;

		var x, z;
		Chunk c;

		if (x >= 0 && x < Section.SIZE && z >= 0 && z < Section.SIZE) {
			c = chunk;
		}
		else {
			int bx = chunk.pos.x * Section.SIZE + x;
			int bz = chunk.pos.z * Section.SIZE + z;

			c = world.GetChunk(bx >> 4, bz >> 4);
			if (c == null) return 0;

			x = bx & 15;
			z = bz & 15;
		}

		uint32 sky = (.) c.GetLight(.Sky, x, y, z);
		uint32 block = (.) c.GetLight(.Block, x, y, z);

		if (block < blockState.luminance) block = blockState.luminance;

	    return PackLightmapUv(sky, block);
	}

	public static uint32 PackLightmapUv(uint32 sky, uint32 block) => sky << 20 | block << 4;
	
	private static bool ShouldRender(ref Foo foo, Quad quad, Direction direction) {
		if (foo.y < 0 || foo.y + direction.GetOffset().y < 0) return false;
		if (foo.y >= Section.SIZE * 16) return true;

		BlockState blockState = foo.Get(direction);

		if (foo.chunk.pos.x * 16 + foo.x == 1422 && foo.y == 179 && foo.chunk.pos.z * 16 + foo.z == -427 && quad.direction == .West) {
			foo.y = foo.y;
		}

		if (blockState.block.transparent) return true;
		if (blockState.model.fullBlock) return false;

		for (Quad otherQuad in blockState.model.GetAdjacentQuads(quad.direction.GetOpposite())) {
			if (TestQuads!(quad, otherQuad.min, otherQuad.max)) return false;
		}

		return true;
	}
	
	private static mixin TestQuads(Quad quad, Vec3f min, Vec3f max) {
		bool a = false;

		switch (quad.direction) {
		case .Up, .Down:     if (quad.min.x >= min.x && quad.max.x <= max.x && quad.min.z >= min.z && quad.max.z <= max.z) a = true;
		case .East, .West:   if (quad.min.y >= min.y && quad.max.y <= max.y && quad.min.z >= min.z && quad.max.z <= max.z) a = true;
		case .North, .South: if (quad.min.x >= min.x && quad.max.x <= max.x && quad.min.y >= min.y && quad.max.y <= max.y) a = true;
		}

		a
	}
	
	private static bool CanOcclude(World world, Chunk chunk, int x, int y, int z) {
		Model model = GetBlock(world, chunk, x, y, z).model;
	    return model != null && model.fullBlock;
	}
	
	private static int Idk(bool side1, bool side2, bool corner) {
	    if (side1 && side2) return 0;
	    return 3 - ((side1 ? 1 : 0) + (side2 ? 1 : 0) + (corner ? 1 : 0));
	}
	
	private static float AoY(World world, Chunk chunk, int x, int y, int z, int vx, int vy, int vz) {
		var vx, vy, vz;

	    if (vx == 0) vx = -1;
	    if (vy == 0) vy = -1;
	    if (vz == 0) vz = -1;

	    return Idk(CanOcclude(world, chunk, x + vx, y + vy, z), CanOcclude(world, chunk, x, y + vy, z + vz), CanOcclude(world, chunk, x + vx, y + vy, z + vz)) / 3.0f;
	}
	
	private static float AoX(World world, Chunk chunk, int x, int y, int z, int vx, int vy, int vz) {
		var vx, vy, vz;

	    if (vx == 0) vx = -1;
	    if (vy == 0) vy = -1;
	    if (vz == 0) vz = -1;

	    return Idk(CanOcclude(world, chunk, x + vx, y + vy, z), CanOcclude(world, chunk, x + vx, y, z + vz), CanOcclude(world, chunk, x + vx, y + vy, z + vz)) / 3.0f;
	}
	
	private static float AoZ(World world, Chunk chunk, int x, int y, int z, int vx, int vy, int vz) {
		var vx, vy, vz;

	    if (vx == 0) vx = -1;
	    if (vy == 0) vy = -1;
	    if (vz == 0) vz = -1;

	    return Idk(CanOcclude(world, chunk, x + vx, y, z + vz), CanOcclude(world, chunk, x, y + vy, z + vz), CanOcclude(world, chunk, x + vx, y + vy, z + vz)) / 3.0f;
	}

	struct Foo {
		private World world;
		public Chunk chunk;
		public int x, y, z;

		private BlockState[6] blockStates;

		public this(World world, Chunk chunk, int x, int y, int z) {
			this.world = world;
			this.chunk = chunk;
			this.x = x;
			this.y = y;
			this.z = z;
			this.blockStates = default;
		}

		public BlockState Get(Direction direction) mut {
			BlockState blockState = blockStates[direction.Underlying];

			if (blockState == null) {
				Vec3i offset = direction.GetOffset();
				blockState = blockStates[direction.Underlying] = GetBlock(world, chunk, x + offset.x, y + offset.y, z + offset.z);
			}

			return blockState;
		}
	}
}