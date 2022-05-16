using System;

namespace Meteorite {
	static class BlockRenderer {
		private enum A {
			None,
			True,
			False
		}

		private static bool IsFilledWithWater(Block block) {
			return block == Blocks.SEAGRASS || block == Blocks.TALL_SEAGRASS || block == Blocks.KELP || block == Blocks.KELP_PLANT;
		}

		private static void RenderFluid(World world, Chunk chunk, int x, int y, int z, BlockState blockState, Biome biome) {
			Block b = chunk.Get(x, y + 1, z).block;
			if (b == Blocks.WATER || b == Blocks.LAVA || IsFilledWithWater(b)) return;

			Quad quad = blockState.model.quads[0];
			Mesh m = blockState.block == Blocks.WATER ? chunk.meshTransparent : chunk.mesh;

			Color c = .(255, 255, 255);
			if (blockState.block == Blocks.WATER) Tint(chunk, blockState, x, y, z, ref c);
			c.a = 255;

			Property p = blockState.GetProperty("level");
			float yOffset = (p.value == 0 ? 15 : 15 - p.value) / 16f;

			m.Quad(
				m.Vec3(.(x + 0, y + yOffset, z + 0)).Vec2(.(quad.region.x1, quad.region.y1)).Color(c).Next(),
				m.Vec3(.(x + 1, y + yOffset, z + 0)).Vec2(.(quad.region.x2, quad.region.y1)).Color(c).Next(),
				m.Vec3(.(x + 1, y + yOffset, z + 1)).Vec2(.(quad.region.x2, quad.region.y2)).Color(c).Next(),
				m.Vec3(.(x + 0, y + yOffset, z + 1)).Vec2(.(quad.region.x1, quad.region.y2)).Color(c).Next()
			);
		}

		public static void Render(World world, Chunk chunk, int x, int y, int z, BlockState blockState, Biome biome) {
			if (blockState.model == null) return;

			if (blockState.block == Blocks.WATER || blockState.block == Blocks.LAVA) {
				RenderFluid(world, chunk, x, y, z, blockState, biome);
				return;
			}
			else if (IsFilledWithWater(blockState.block)) RenderFluid(world, chunk, x, y, z, Blocks.WATER.defaultBlockState, biome);

			Mesh m = chunk.mesh;

			A top = .None;
			A bottom = .None;
			A north = .None;
			A south = .None;
			A east = .None;
			A west = .None;

			for (Quad quad in blockState.model.quads) {
				switch (quad.cullFace) {
				case .Top:
					if (top == .None) top = ShouldRender(world, chunk, x, y + 1, z);
					if (top == .False) continue;
				case .Bottom:
					if (bottom == .None) bottom = ShouldRender(world, chunk, x, y - 1, z);
					if (bottom == .False) continue;
				case .North:
					if (north == .None) north = ShouldRender(world, chunk, x, y, z - 1);
					if (north == .False) continue;
				case .South:
					if (south == .None) south = ShouldRender(world, chunk, x, y, z + 1);
					if (south == .False) continue;
				case .East:
					if (east == .None) east = ShouldRender(world, chunk, x + 1, y, z);
					if (east == .False) continue;
				case .West:
					if (west == .None) west = ShouldRender(world, chunk, x - 1, y, z);
					if (west == .False) continue;
				default:
				}

				float ao1 = 1;
				float ao2 = 1;
				float ao3 = 1;
				float ao4 = 1;

				if (Program.AO && !blockState.block.transparent) {
				    switch (quad.direction) {
			        case .Up:
			            ao1 = AoY(world, chunk, x, y, z, (.) quad.vertices[0].x, 1, (.) quad.vertices[0].z);
			            ao2 = AoY(world, chunk, x, y, z, (.) quad.vertices[1].x, 1, (.) quad.vertices[1].z);
			            ao3 = AoY(world, chunk, x, y, z, (.) quad.vertices[2].x, 1, (.) quad.vertices[2].z);
			            ao4 = AoY(world, chunk, x, y, z, (.) quad.vertices[3].x, 1, (.) quad.vertices[3].z);
			        case .Down:
			            ao1 = AoY(world, chunk, x, y, z, (.) quad.vertices[0].x, 0, (.) quad.vertices[0].z);
			            ao2 = AoY(world, chunk, x, y, z, (.) quad.vertices[1].x, 0, (.) quad.vertices[1].z);
			            ao3 = AoY(world, chunk, x, y, z, (.) quad.vertices[2].x, 0, (.) quad.vertices[2].z);
			            ao4 = AoY(world, chunk, x, y, z, (.) quad.vertices[3].x, 0, (.) quad.vertices[3].z);
			        case .East:
			            ao1 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[0].y, (.) quad.vertices[0].z);
			            ao2 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[1].y, (.) quad.vertices[1].z);
			            ao3 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[2].y, (.) quad.vertices[2].z);
			            ao4 = AoX(world, chunk, x, y, z, 1, (.) quad.vertices[3].y, (.) quad.vertices[3].z);
			        case .West:
			            ao1 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[0].y, (.) quad.vertices[0].z);
			            ao2 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[1].y, (.) quad.vertices[1].z);
			            ao3 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[2].y, (.) quad.vertices[2].z);
			            ao4 = AoX(world, chunk, x, y, z, 0, (.) quad.vertices[3].y, (.) quad.vertices[3].z);
			        case .North:
			            ao1 = AoZ(world, chunk, x, y, z, (.) quad.vertices[0].x, (.) quad.vertices[0].y, 0);
			            ao2 = AoZ(world, chunk, x, y, z, (.) quad.vertices[1].x, (.) quad.vertices[1].y, 0);
			            ao3 = AoZ(world, chunk, x, y, z, (.) quad.vertices[2].x, (.) quad.vertices[2].y, 0);
			            ao4 = AoZ(world, chunk, x, y, z, (.) quad.vertices[3].x, (.) quad.vertices[3].y, 0);
			        case .South:
			            ao1 = AoZ(world, chunk, x, y, z, (.) quad.vertices[0].x, (.) quad.vertices[0].y, 1);
			            ao2 = AoZ(world, chunk, x, y, z, (.) quad.vertices[1].x, (.) quad.vertices[1].y, 1);
			            ao3 = AoZ(world, chunk, x, y, z, (.) quad.vertices[2].x, (.) quad.vertices[2].y, 1);
			            ao4 = AoZ(world, chunk, x, y, z, (.) quad.vertices[3].x, (.) quad.vertices[3].y, 1);
					default:
			        }
				}

			    ao1 = ao1 / 2.0f + 0.5f;
			    ao2 = ao2 / 2.0f + 0.5f;
			    ao3 = ao3 / 2.0f + 0.5f;
			    ao4 = ao4 / 2.0f + 0.5f;

				Color c = .(255, 255, 255);
				if (quad.tint && biome != null) Tint(chunk, blockState, x, y, z, ref c);

				switch (quad.direction) {
				case .Up:
					m.Quad(
						m.Vec3(.(x + quad.vertices[0].x, y + quad.vertices[0].y, z + quad.vertices[0].z)).Vec2(.(quad.region.x1, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao1)).Next(),
						m.Vec3(.(x + quad.vertices[1].x, y + quad.vertices[1].y, z + quad.vertices[1].z)).Vec2(.(quad.region.x2, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao2)).Next(),
						m.Vec3(.(x + quad.vertices[2].x, y + quad.vertices[2].y, z + quad.vertices[2].z)).Vec2(.(quad.region.x2, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao3)).Next(),
						m.Vec3(.(x + quad.vertices[3].x, y + quad.vertices[3].y, z + quad.vertices[3].z)).Vec2(.(quad.region.x1, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao4)).Next()
					);
				case .Down:
					m.Quad(
						m.Vec3(.(x + quad.vertices[0].x, y + quad.vertices[0].y, z + quad.vertices[0].z)).Vec2(.(quad.region.x1, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao1)).Next(),
						m.Vec3(.(x + quad.vertices[1].x, y + quad.vertices[1].y, z + quad.vertices[1].z)).Vec2(.(quad.region.x1, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao2)).Next(),
						m.Vec3(.(x + quad.vertices[2].x, y + quad.vertices[2].y, z + quad.vertices[2].z)).Vec2(.(quad.region.x2, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao3)).Next(),
						m.Vec3(.(x + quad.vertices[3].x, y + quad.vertices[3].y, z + quad.vertices[3].z)).Vec2(.(quad.region.x2, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao4)).Next()
					);
				case .North, .East:
					m.Quad(
						m.Vec3(.(x + quad.vertices[0].x, y + quad.vertices[0].y, z + quad.vertices[0].z)).Vec2(.(quad.region.x2, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao1)).Next(),
						m.Vec3(.(x + quad.vertices[1].x, y + quad.vertices[1].y, z + quad.vertices[1].z)).Vec2(.(quad.region.x1, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao2)).Next(),
						m.Vec3(.(x + quad.vertices[2].x, y + quad.vertices[2].y, z + quad.vertices[2].z)).Vec2(.(quad.region.x1, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao3)).Next(),
						m.Vec3(.(x + quad.vertices[3].x, y + quad.vertices[3].y, z + quad.vertices[3].z)).Vec2(.(quad.region.x2, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao4)).Next()
					);
				case .South, .West:
					m.Quad(
						m.Vec3(.(x + quad.vertices[0].x, y + quad.vertices[0].y, z + quad.vertices[0].z)).Vec2(.(quad.region.x1, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao1)).Next(),
						m.Vec3(.(x + quad.vertices[1].x, y + quad.vertices[1].y, z + quad.vertices[1].z)).Vec2(.(quad.region.x1, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao2)).Next(),
						m.Vec3(.(x + quad.vertices[2].x, y + quad.vertices[2].y, z + quad.vertices[2].z)).Vec2(.(quad.region.x2, quad.region.y1)).Color(c.MulWithoutA(quad.light * ao3)).Next(),
						m.Vec3(.(x + quad.vertices[3].x, y + quad.vertices[3].y, z + quad.vertices[3].z)).Vec2(.(quad.region.x2, quad.region.y2)).Color(c.MulWithoutA(quad.light * ao4)).Next()
					);
				default:
				}
			}
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

						Color co = BlockColors.Get(blockState.block, bi);
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

		private static Block GetBlock(World world, Chunk chunk, int x, int y, int z) {
			if (y < 0) return Blocks.AIR;
			if (y >= Section.SIZE * 16) return Blocks.AIR;
			if (x >= 0 && x < Section.SIZE && z >= 0 && z < Section.SIZE) return chunk.Get(x, y, z).block;

			int bx = chunk.pos.x * Section.SIZE + x;
			int bz = chunk.pos.z * Section.SIZE + z;

			Chunk c = world.GetChunk(bx >> 4, bz >> 4);
			if (c == null) return Blocks.AIR;

			return c.Get(bx & 15, y, bz & 15).block;
		}

		private static A ShouldRender(World world, Chunk chunk, int x, int y, int z) {
			if (y < 0) return .False;
			if (y >= Section.SIZE * 16) return .True;
			if (x >= 0 && x < Section.SIZE && z >= 0 && z < Section.SIZE) return chunk.Get(x, y, z).block.transparent ? .True : .False;

			int bx = chunk.pos.x * Section.SIZE + x;
			int bz = chunk.pos.z * Section.SIZE + z;

			Chunk c = world.GetChunk(bx >> 4, bz >> 4);
			if (c == null) return .False;

			return c.Get(bx & 15, y, bz & 15).block.transparent ? .True : .False;
		}

		private static bool CanOcclude(World world, Chunk chunk, int x, int y, int z) {
		    return !GetBlock(world, chunk, x, y, z).transparent;
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
	}
}