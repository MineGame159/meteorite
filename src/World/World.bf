using System;
using System.Collections;
using System.Diagnostics;

using Cacti;

namespace Meteorite;

class World : IBlockGetter {
	public append Registries registries = .();
	public DimensionType dimension ~ delete _;

	private Dictionary<ChunkPos, Chunk> chunks;

	private Dictionary<int, Entity> entities = new .() ~ DeleteDictionaryAndValues!(_);

	public int64 worldAge, timeOfDay;

	public this(DimensionType dimension) {
		this.dimension = dimension;
		this.chunks = new Dictionary<ChunkPos, Chunk>();
	}

	public ~this() {
		for (Chunk chunk in chunks.Values) {
			chunk.[Friend]ForceDelete();
		}

		delete chunks;
	}

	public Dictionary<ChunkPos, Chunk>.ValueEnumerator Chunks => chunks.Values;
	public Dictionary<int, Entity>.ValueEnumerator Entities => entities.Values;

	public int SectionCount => dimension.height / Section.SIZE;
	public int ChunkCount => chunks.Count;
	public int EntityCount => entities.Count;

	public int BlockEntityCount { get {
		int count = 0;
		for (Chunk chunk in Chunks) count += chunk.BlockEntityCount;
		return count;
	} }

	public void AddChunk(Chunk chunk) {
		ChunkPos p;
		Chunk c;
		bool replacing = chunks.TryGet(chunk.pos, out p, out c);

		if (replacing) {
			c.Release();
		}

		chunks[chunk.pos] = chunk;
	}

	public Chunk GetChunk(int x, int z) {
		return chunks.GetValueOrDefault(.(x, z));
	}

	public bool IsChunkLoaded(int x, int z) {
		return chunks.ContainsKey(.(x, z));
	}

	public BlockState GetBlock(int x, int y, int z) {
		Chunk chunk = GetChunk(x >> 4, z >> 4);
		return chunk != null ? chunk.Get(x & 15, y, z & 15) : Blocks.AIR.defaultBlockState;
	}
	public BlockState GetBlock(Vec3i pos) => GetBlock(pos.x, pos.y, pos.z); // Bruh

	public void SetBlock(int x, int y, int z, BlockState blockState) {
		Chunk chunk = GetChunk(x >> 4, z >> 4);
		if (chunk != null) chunk.Set(x & 15, y, z & 15, blockState);
	}

	public BlockEntity GetBlockEntity(int x, int y, int z) {
		Chunk chunk = GetChunk(x >> 4, z >> 4);
		return chunk != null ? chunk.GetBlockEntity(x & 15, y, z & 15) : null;
	}

	public void RemoveBlockEntity(int x, int y, int z) {
		Chunk chunk = GetChunk(x >> 4, z >> 4);
		if (chunk != null) chunk.RemoveBlockEntity(x & 15, y, z & 15);
	}

	public Biome GetBiome(int x, int y, int z) {
		Chunk chunk = GetChunk(x >> 4, z >> 4);
		return chunk != null ? chunk.GetBiome(x & 15, y, z & 15) : Biomes.VOID;
	}

	public void ReloadChunks() {
		for (Chunk chunk in chunks.Values) chunk.dirty = true;
	}

	public void AddEntity(Entity entity) {
		int outId;
		Entity outEntity;
		if (entities.TryGet(entity.id, out outId, out outEntity)) delete outEntity;

		entities[entity.id] = entity;

		if (entity is ClientPlayerEntity) Meteorite.INSTANCE.player = (.) entity;
	}

	public void RemoveEntity(int entityId) {
		if (entities.GetAndRemove(entityId) case .Ok(let val)) delete val.value;
	}

	public Entity GetEntity(int entityId) {
		return entities.GetValueOrDefault(entityId);
	}
	
	[Tracy.Profile]
	public void Tick() {
		for (Entity entity in entities.Values) {
			entity.tickCount++;
			entity.Tick();
		}

		if (Meteorite.INSTANCE.player != null) {
			int x = ((.) Meteorite.INSTANCE.player.pos.x >> 4);
			int z = ((.) Meteorite.INSTANCE.player.pos.z >> 4);

			for (Chunk chunk in Chunks) {
				if (IsChunkInRange(chunk.pos.x, chunk.pos.z, x, z)) continue;

				@chunk.Remove();
				chunk.Release();
			}
		}
	}

	public bool IsChunkInRange(int x1, int z1, int x2, int z2) {
		int renderDistance = Meteorite.INSTANCE.options.renderDistance;
		return Math.Abs(x1 - x2) <= renderDistance + 1 && Math.Abs(z1 - z2) <= renderDistance + 1;
	}
	
	[Tracy.Profile]
	public BlockHitResult Raycast(Vec3d start, Vec3d end) {
		return Raycast(start, end, scope (pos) => {
			BlockState blockState = GetBlock(pos);
			VoxelShape shape = blockState.Shape;

			return RaycastBlock(start, end, pos, shape, blockState);
		}, scope () => {
			return new BlockHitResult(end, .(), .GetFacing(start - end), true);
		});
	}

	private BlockHitResult RaycastBlock(Vec3d start, Vec3d end, Vec3i pos, VoxelShape shape, BlockState blockState) {
		if (shape == null) return null;

		BlockHitResult blockHitResult2 = null;
		BlockHitResult blockHitResult = shape.Raycast(start, end, pos);

		if (blockHitResult != null && blockState.RaycastShape != null && (blockHitResult2 = blockState.RaycastShape.Raycast(start, end, pos)) != null && (blockHitResult2.pos - start).LengthSquared < (blockHitResult.pos - start).LengthSquared) {
			blockHitResult.side = blockHitResult2.side;
		}

		delete blockHitResult2;
		return blockHitResult;
	}

	public T Raycast<T>(Vec3d start, Vec3d end, delegate T(Vec3i) blockHitFactory, delegate T() missFactory) {
		int l, k;
		if (start == end) return missFactory();

		double d = Math.Lerp(end.x, start.x, -1.0E-7);
		double e = Math.Lerp(end.y, start.y, -1.0E-7);
		double f = Math.Lerp(end.z, start.z, -1.0E-7);
		double g = Math.Lerp(start.x, end.x, -1.0E-7);
		double h = Math.Lerp(start.y, end.y, -1.0E-7);
		double i = Math.Lerp(start.z, end.z, -1.0E-7);
		int j = (.) Math.Floor(g);

		T object = blockHitFactory(.(j, k = (.) Math.Floor(h), l = (.) Math.Floor(i)));
		if (object != null) return object;

		double m = d - g;
		double n = e - h;
		double o = f - i;

		int p = Math.Sign(m);
		int q = Math.Sign(n);
		int r = Math.Sign(o);

		double s = p == 0 ? double.MaxValue : (double) p / m;
		double t = q == 0 ? double.MaxValue : (double) q / n;
		double u = r == 0 ? double.MaxValue : (double) r / o;

		double v = s * (p > 0 ? 1.0 - Utils.FractionalPart(g) : Utils.FractionalPart(g));
		double w = t * (q > 0 ? 1.0 - Utils.FractionalPart(h) : Utils.FractionalPart(h));
		double x = u * (r > 0 ? 1.0 - Utils.FractionalPart(i) : Utils.FractionalPart(i));

		while (v <= 1.0 || w <= 1.0 || x <= 1.0) {
		    T object2;
		    if (v < w) {
		        if (v < x) {
		            j += p;
		            v += s;
		        } else {
		            l += r;
		            x += u;
		        }
		    } else if (w < x) {
		        k += q;
		        w += t;
		    } else {
		        l += r;
		        x += u;
		    }
		    if ((object2 = blockHitFactory(.(j, k, l))) == null) continue;
		    return object2;
		}

		return missFactory();
	}

	public void GetPossibleCollisions(AABB aabb, delegate void(Vec3d, VoxelShape) callback) {
		int minX = (.) Math.Floor(aabb.min.x - 1.0E-7) - 1;
		int minY = (.) Math.Floor(aabb.min.y - 1.0E-7) - 1;
		int minZ = (.) Math.Floor(aabb.min.z - 1.0E-7) - 1;

		int maxX = (.) Math.Floor(aabb.max.x + 1.0E-7) + 1;
		int maxY = (.) Math.Floor(aabb.max.y + 1.0E-7) + 1;
		int maxZ = (.) Math.Floor(aabb.max.z + 1.0E-7) + 1;

		for (int x = minX; x <= maxX; x++) {
			for (int y = minY; y <= maxY; y++) {
				for (int z = minZ; z <= maxZ; z++) {
					BlockState blockState = Meteorite.INSTANCE.world.GetBlock(x, y, z);
					VoxelShape shape = blockState.CollisionShape;

					if (shape != null) {
						/*if (shape == VoxelShapes.BLOCK) {
							Vec3d pos = .(x, y, z);
							//if (aabb.Intersects(pos, pos + .(1, 1, 1))) callback(pos, shape);
							callback(pos, shape);
						}
						else callback(.(x, y, z), shape);*/

						for (let shapeAabb in shape.[Friend]boxes) {
							if (shapeAabb.Offset(.(x, y, z)).Intersects(aabb)) {
								callback(.(x, y, z), shape);
								break;
							}
						}
					}
				}
			}
		}
	}

	public Vec3f GetSkyColor(Vec3f cameraPos, double tickDelta) {
		float f = GetSkyAngle();
		Vec3f vec3 = cameraPos - Vec3f(2, 2, 2);
		Vec3f vec32 = CubicSampler.SampleColor(vec3, scope (x, y, z) => GetBiome(x, y, z).skyColor.ToVec3f);
		float g = Math.Cos(f * (float) (Math.PI_d * 2)) * 2.0F + 0.5F;
		g = Math.Clamp(g, 0.0F, 1.0F);
		float h = (float)vec32.x * g;
		float i = (float)vec32.y * g;
		float j = (float)vec32.z * g;
		float k = GetRainLevel(tickDelta);
		if (k > 0.0F) {
			float l = (h * 0.3F + i * 0.59F + j * 0.11F) * 0.6F;
			float m = 1.0F - k * 0.75F;
			h = h * m + l * (1.0F - m);
			i = i * m + l * (1.0F - m);
			j = j * m + l * (1.0F - m);
		}

		float l = GetThunderLevel(tickDelta);
		if (l > 0.0F) {
			float m = (h * 0.3F + i * 0.59F + j * 0.11F) * 0.2F;
			float n = 1.0F - l * 0.75F;
			h = h * n + m * (1.0F - n);
			i = i * n + m * (1.0F - n);
			j = j * n + m * (1.0F - n);
		}

		// TODO: Sky flash
		/*if (!this.minecraft.options.hideLightningFlashes && this.skyFlashTime > 0) {
			float m = (float)this.skyFlashTime - partialTick;
			if (m > 1.0F) {
				m = 1.0F;
			}

			m *= 0.45F;
			h = h * (1.0F - m) + 0.8F * m;
			i = i * (1.0F - m) + 0.8F * m;
			j = j * (1.0F - m) + 1.0F * m;
		}*/

		return .(h, i, j);
	}

	public Vec4f? GetSunriseColor(float timeOfDay) {
		float f = 0.4F;
		float g = Math.Cos(timeOfDay * (Math.PI_f * 2)) - 0.0F;
		float h = -0.0F;

		if (g >= -f && g <= f) {
			float i = (g - h) / f * 0.5F + 0.5F;
			float j = 1.0F - (1.0F - Math.Sin(i * Math.PI_f)) * 0.99F;
			j *= j;
			return .(i * 0.3F + 0.7F, i * i * 0.7F + 0.2F, i * i * 0.0F + 0.2F, j);
		}

		return null;
	}

	public float GetSkyAngle() {
		double d = Utils.FractionalPart((double) dimension.fixedTime.GetValueOrDefault(timeOfDay) / 24000.0 - 0.25);
		double e = 0.5 - Math.Cos(d * Math.PI_d) / 2.0;
		return (float) (d * 2.0 + e) / 3.0f;
	}

	public float GetCelestialAngle() {
		float f = GetSkyAngle();
		return f * (Math.PI_f * 2);
	}

	public int GetMoonPhase() => (timeOfDay / 24000L % 8L + 8L) % 8;

	public float GetStarBrightness(float tickDelta = 1) {
		float f = GetSkyAngle();
		float g = 1.0F - (Math.Cos(f * (float) (Math.PI_f * 2)) * 2.0F + 0.25F);
		g = Math.Clamp(g, 0.0F, 1.0F);
		return g * g * 0.5F;
	}

	public float GetSkyDarken(float tickDelta = 1) {
		float f = GetSkyAngle();
		float g = 1.0f - (Math.Cos(f * ((float) Math.PI_f * 2)) * 2.0f + 0.2f);
		g = Math.Clamp(g, 0.0f, 1.0f);
		g = 1.0f - g;
		g *= 1.0f - GetRainLevel(tickDelta) * 5.0f / 16.0f;
		return (g *= 1.0f - GetThunderLevel(tickDelta) * 5.0f / 16.0f) * 0.8f + 0.2f;
	}

	public float GetRainLevel(double tickDelta) => 0;
	public float GetThunderLevel(double tickDelta) => 0;
	public float GetDarkenWorldAmount(double tickDelta) => 0;

	// TODO: Hardcoded overworld
	public Vec3f GetBrightnessDependentFogColor(Vec3f fogColor, float brightness) {
		return fogColor * Vec3f((brightness * 0.94F + 0.06F), (brightness * 0.94F + 0.06F), (brightness * 0.91F + 0.09F));
	}

	public Color GetClearColor(Camera camera, double tickDelta) {
		float fogRed;
		float fogGreen;
		float fogBlue;

		{
			float r = 0.25F + 0.75F * (float) Meteorite.INSTANCE.options.renderDistance / 32.0F;
			r = 1.0F - (float)Math.Pow((double)r, 0.25);
			Vec3f vec3 = GetSkyColor((.) camera.pos, tickDelta);
			float s = (float)vec3.x;
			float t = (float)vec3.y;
			float u = (float)vec3.z;
			float v = Math.Clamp(Math.Cos(GetSkyAngle() * (float) (Math.PI_f * 2)) * 2.0F + 0.5F, 0.0F, 1.0F);
			Vec3f vec32 = (.) camera.pos - Vec3f(2, 2, 2);
			Vec3f vec33 = CubicSampler.SampleColor(vec32, scope (x, y, z) => GetBrightnessDependentFogColor(GetBiome(x, y, z).fogColor.ToVec3f, v));
			fogRed = (float)vec33.x;
			fogGreen = (float)vec33.y;
			fogBlue = (float)vec33.z;
			if (Meteorite.INSTANCE.options.renderDistance >= 4) {
				float f = Math.Sin(GetSkyAngle()) > 0.0F ? -1.0F : 1.0F;
				Vec3f vector3f = .(f, 0.0F, 0.0F);
				float h = (.) camera.GetDirection(true).Dot(vector3f);
				if (h < 0.0F) {
					h = 0.0F;
				}

				if (h > 0.0F) {
					Vec4f? sunriseColor = GetSunriseColor(GetSkyAngle());
					if (sunriseColor != null) {
						h *= sunriseColor.Value.w;
						fogRed = fogRed * (1.0F - h) + sunriseColor.Value.x * h;
						fogGreen = fogGreen * (1.0F - h) + sunriseColor.Value.y * h;
						fogBlue = fogBlue * (1.0F - h) + sunriseColor.Value.z * h;
					}
				}
			}

			fogRed += (s - fogRed) * r;
			fogGreen += (t - fogGreen) * r;
			fogBlue += (u - fogBlue) * r;
			float f = GetRainLevel(tickDelta);
			if (f > 0.0F) {
				float g = 1.0F - f * 0.5F;
				float h = 1.0F - f * 0.4F;
				fogRed *= g;
				fogGreen *= g;
				fogBlue *= h;
			}

			float g = GetThunderLevel(tickDelta);
			if (g > 0.0F) {
				float h = 1.0F - g * 0.5F;
				fogRed *= h;
				fogGreen *= h;
				fogBlue *= h;
			}
		}

		//

		float r = ((float)camera.pos.y - (float)dimension.minY) * 0.03125F; // TODO: Dimension clear color scale
		// TODO: Blindness
		/*if (activeRenderInfo.getEntity() instanceof LivingEntity && ((LivingEntity)activeRenderInfo.getEntity()).hasEffect(MobEffects.BLINDNESS)) {
			int w = ((LivingEntity)activeRenderInfo.getEntity()).getEffect(MobEffects.BLINDNESS).getDuration();
			if (w < 20) {
				r = 1.0F - (float)w / 20.0F;
			} else {
				r = 0.0F;
			}
		}*/

		if (r < 1.0F/* && fogType != FogType.LAVA && fogType != FogType.POWDER_SNOW*/) {
			if (r < 0.0F) {
				r = 0.0F;
			}

			r *= r;
			fogRed *= r;
			fogGreen *= r;
			fogBlue *= r;
		}

		float bossColorModifier = GetDarkenWorldAmount(tickDelta);
		if (bossColorModifier > 0.0F) {
			fogRed = fogRed * (1.0F - bossColorModifier) + fogRed * 0.7F * bossColorModifier;
			fogGreen = fogGreen * (1.0F - bossColorModifier) + fogGreen * 0.6F * bossColorModifier;
			fogBlue = fogBlue * (1.0F - bossColorModifier) + fogBlue * 0.6F * bossColorModifier;
		}

		float x = 0; // TODO: Idk
		/*if (fogType == FogType.WATER) {
			if (entity instanceof LocalPlayer) {
				x = ((LocalPlayer)entity).getWaterVision();
			} else {
				x = 1.0F;
			}
		} else if (entity instanceof LivingEntity && ((LivingEntity)entity).hasEffect(MobEffects.NIGHT_VISION)) {
			x = GameRenderer.getNightVisionScale((LivingEntity)entity, partialTicks);
		} else {
			x = 0.0F;
		}*/

		if (fogRed != 0.0F && fogGreen != 0.0F && fogBlue != 0.0F) {
			float s = Math.Min(1.0F / fogRed, Math.Min(1.0F / fogGreen, 1.0F / fogBlue));
			fogRed = fogRed * (1.0F - x) + fogRed * s * x;
			fogGreen = fogGreen * (1.0F - x) + fogGreen * s * x;
			fogBlue = fogBlue * (1.0F - x) + fogBlue * s * x;
		}

		return .(fogRed, fogGreen, fogBlue, 1);
	}
}