using System;

namespace Meteorite {
	static class BlockRenderer {
		private static bool IsFilledWithWater(Block block) {
			return block == Blocks.SEAGRASS || block == Blocks.TALL_SEAGRASS || block == Blocks.KELP || block == Blocks.KELP_PLANT;
		}
		
		private static void RenderFluid(World world, Chunk chunk, int x, int y, int z, BlockState blockState, Biome biome) {
			Block b = chunk.Get(x, y + 1, z).block;
			if (b == Blocks.WATER || b == Blocks.LAVA || IsFilledWithWater(b)) return;

			Quad quad = blockState.model.quads[0];
			MeshBuilder mb = (blockState.block == Blocks.WATER ? chunk.meshTransparent : chunk.mesh).Build();

			Color c = .(255, 255, 255);
			if (blockState.block == Blocks.WATER) Tint(chunk, blockState, x, y, z, ref c);
			c.a = 255;

			Property p = blockState.GetProperty("level");
			float yOffset = (p.value == 0 ? 15 : 15 - p.value) / 16f;

			uint32 i1 = Vertex!(mb, x, y, z, Vertex(.(0, yOffset, 0), quad.vertices[0].uv), quad.texture, c);
			uint32 i2 = Vertex!(mb, x, y, z, Vertex(.(1, yOffset, 0), quad.vertices[1].uv), quad.texture, c);
			uint32 i3 = Vertex!(mb, x, y, z, Vertex(.(1, yOffset, 1), quad.vertices[2].uv), quad.texture, c);
			uint32 i4 = Vertex!(mb, x, y, z, Vertex(.(0, yOffset, 1), quad.vertices[3].uv), quad.texture, c);

			mb.Quad(i1, i2, i3, i4); // Top
			mb.Quad(i1, i4, i3, i2); // Bottom
		}
		
		public static void Render(World world, Chunk chunk, int x, int y, int z, BlockState blockState, Biome biome) {
			if (blockState.model == null) return;

			if (blockState.block == Blocks.WATER || blockState.block == Blocks.LAVA) {
				RenderFluid(world, chunk, x, y, z, blockState, biome);
				return;
			}
			else if (IsFilledWithWater(blockState.block)) RenderFluid(world, chunk, x, y, z, Blocks.WATER.defaultBlockState, biome);

			Foo foo = .(world, chunk, x, y, z);
			MeshBuilder mb = (blockState.block == Blocks.NETHER_PORTAL ? chunk.meshTransparent : chunk.mesh).Build(); // TODO: Fix this
			bool ao = Meteorite.INSTANCE.options.ao;

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

				// Tint
				Color c = .(255, 255, 255);
				if (quad.tint && biome != null) Tint(chunk, blockState, x, y, z, ref c);
				
				// Emit quad
				mb.Quad(
					Vertex!(mb, x, y, z, quad.vertices[0], quad.texture, c.MulWithoutA(quad.light * ao1)),
					Vertex!(mb, x, y, z, quad.vertices[1], quad.texture, c.MulWithoutA(quad.light * ao2)),
					Vertex!(mb, x, y, z, quad.vertices[2], quad.texture, c.MulWithoutA(quad.light * ao3)),
					Vertex!(mb, x, y, z, quad.vertices[3], quad.texture, c.MulWithoutA(quad.light * ao4))
				);
			}
		}

		private static mixin Vertex(MeshBuilder mb, int x, int y, int z, Vertex v, uint16 texture, Color color) {
			mb
				.Vec3(.(x + v.pos.x, y + v.pos.y, z + v.pos.z))
				.UShort2(v.uv.x, v.uv.y)
				.Color(color)
				.UShort2(texture, 0)
				.Next()
		}

		private static void Tint(Chunk chunk, BlockState blockState, int x, int y, int z, ref Color color) {
			int r = 0;
			int g = 0;
			int b = 0;

			int s = true ? 1 : 0;

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

			if (y < 0 || y >= world.height) return null;
			if (x >= 0 && x < Section.SIZE && z >= 0 && z < Section.SIZE) return chunk.GetSection(y >> world.SectionCount).GetBiome(x, y % world.SectionCount, z);

			int bx = chunk.pos.x * Section.SIZE + x;
			int bz = chunk.pos.z * Section.SIZE + z;

			Chunk c = world.GetChunk(bx >> 4, bz >> 4);
			if (c == null) return null;

			Section s = c.GetSection(y >> 4);
			return s == null ? null : s.GetBiome(x, y % world.SectionCount, z);
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
}