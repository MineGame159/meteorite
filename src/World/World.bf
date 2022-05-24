using System;
using System.Collections;
using System.Diagnostics;

namespace Meteorite {
	class World {
		public int viewDistance;

		private Dictionary<ChunkPos, Chunk> chunks ~ DeleteDictionaryAndValues!(_);
		private List<Chunk> visibleChunks = new .() ~ delete _;
		private List<Chunk> chunksToDelete = new .() ~ delete _;

		private Dictionary<int, Entity> entities = new .() ~ DeleteDictionaryAndValues!(_);

		private Mesh meshEntities ~ delete _;
		private Mesh meshLines ~ delete _;

		private ThreadPool threadPool;

		public int minY, height;
		public int renderedChunks;

		public int64 worldAge, timeOfDay;

		private bool shuttingDown;

		public this(int viewDistance, int minY, int height) {
			this.viewDistance = viewDistance;
			this.chunks = new Dictionary<ChunkPos, Chunk>();
			this.threadPool = new .();
			this.minY = minY;
			this.height = height;
		}

		public ~this() {
			shuttingDown = true;

			// Thread pool needs to be deleted before ending un-uploaded meshes
			delete threadPool;

			for (Chunk chunk in chunks.Values) {
				if (chunk.status == .Upload) {
					chunk.mesh.End(false);
					chunk.meshTransparent.End(false);
				}
			}
		}

		public int SectionCount => height / Section.SIZE;
		public int ChunkCount => chunks.Count;
		public int EntityCount => entities.Count;

		public void AddChunk(Chunk chunk) {
			ChunkPos p;
			Chunk c;
			if (chunks.TryGet(chunk.pos, out p, out c)) chunksToDelete.Add(c);

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

		public Biome GetBiome(int x, int y, int z) {
			Chunk chunk = GetChunk(x >> 4, z >> 4);
			return chunk != null ? chunk.GetBiome(x & 15, y, z & 15) : Biomes.VOID;
		}

		public void ReloadChunks() {
			for (Chunk chunk in chunks.Values) chunk.dirty = true;
		}

		public void AddEntity(Entity entity) {
			entities[entity.id] = entity;

			if (entity is ClientPlayerEntity) Meteorite.INSTANCE.player = (.) entity;
		}

		public void RemoveEntity(int entityId) {
			if (entities.GetAndRemove(entityId) case .Ok(let val)) delete val.value;
		}

		public Entity GetEntity(int entityId) {
			return entities.GetValueOrDefault(entityId);
		}

		public void Tick() {
			for (Entity entity in entities.Values) entity.Tick();

			if (Meteorite.INSTANCE.player != null) {
				int x = ((.) Meteorite.INSTANCE.player.pos.x >> 4);
				int z = ((.) Meteorite.INSTANCE.player.pos.z >> 4);
	
				for (Chunk chunk in chunks.Values) {
					if (IsChunkInRange(chunk.pos.x, chunk.pos.z, x, z)) continue;

					@chunk.Remove();
					chunksToDelete.Add(chunk);
				}
			}

			for (Chunk chunk in chunksToDelete) {
				if (chunk.status == .Building) continue;

				@chunk.Remove();
				delete chunk;
			}
		}

		public bool IsChunkInRange(int x1, int z1, int x2, int z2) {
			return Math.Abs(x1 - x2) <= viewDistance + 1 && Math.Abs(z1 - z2) <= viewDistance + 1;
		}

		public void Render(Camera camera, double tickDelta, bool mipmaps, bool sortChunks) {
			Gfx.PushDebugGroup("World");

			// Gather visible chunks
			visibleChunks.Clear();
			renderedChunks = 0;

			for (Chunk chunk in chunks.Values) {
				if (chunk.dirty && chunk.status == .Ready && IsChunkLoaded(chunk.pos.x + 1, chunk.pos.z) && IsChunkLoaded(chunk.pos.x - 1, chunk.pos.z) && IsChunkLoaded(chunk.pos.x, chunk.pos.z + 1) && IsChunkLoaded(chunk.pos.x, chunk.pos.z - 1)) {
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

				if (camera.IsBoxVisible(chunk.min, chunk.max)) {
					visibleChunks.Add(chunk);
					renderedChunks++;
				}
			}

			// Sort chunks
			if (sortChunks) {
				visibleChunks.Sort(scope (lhs, rhs) => {
					double x1 = (lhs.pos.x + 0.5) * 16 - camera.pos.x;
					double z1 = (lhs.pos.z + 0.5) * 16 - camera.pos.z;
					double dist1 = x1 * x1 + z1 * z1;

					double x2 = (rhs.pos.x + 0.5) * 16 - camera.pos.x;
					double z2 = (rhs.pos.z + 0.5) * 16 - camera.pos.z;
					double dist2 = x2 * x2 + z2 * z2;

					return dist2.CompareTo(dist1);
				});
			}

			// Sky
			SkyRenderer.Render(this, camera, tickDelta);

			// Chunks solid
			ChunkPushConstants pc = .();
			pc.projectionView = camera.proj * camera.view;

			Gfx.PushDebugGroup("Chunks - Solid");
			Gfxa.CHUNK_PIPELINE.Bind();
			Meteorite.INSTANCE.textures.Bind(mipmaps);


			for (Chunk chunk in visibleChunks) {
				if (chunk.mesh == null) continue;

				pc.chunkPos = .(chunk.pos.x * Section.SIZE, chunk.pos.z * Section.SIZE);
				Gfx.SetPushConstants(.Vertex, 0, sizeof(ChunkPushConstants), &pc);
				chunk.mesh.Render();
			}

			Gfx.PopDebugGroup();

			// Entities
			Gfx.PushDebugGroup("Entities");
			Gfxa.QUADS_PIPELINE.Bind();
			Gfx.SetPushConstants(.Vertex, 0, sizeof(Mat4), &pc.projectionView);

			if (meshEntities == null) meshEntities = new .(Buffers.QUAD_INDICES);
			meshEntities.Begin();

			for (Entity entity in entities.Values) {
				if (entity == Meteorite.INSTANCE.player && Meteorite.INSTANCE.player.gamemode == .Spectator) continue;

				entity.Render(meshEntities, tickDelta);
			}

			meshEntities.End();
			meshEntities.Render();

			Gfx.PopDebugGroup();

			// Chunks transparent
			Gfx.PushDebugGroup("Chunks - Transparent");
			Gfxa.CHUNK_TRANSPARENT_PIPELINE.Bind();
			Meteorite.INSTANCE.textures.Bind(mipmaps);

			for (Chunk chunk in visibleChunks) {
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
			chunk.mesh.Begin();
			chunk.meshTransparent.Begin();

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

			if (shuttingDown) {
				chunk.mesh.End(false);
				chunk.meshTransparent.End(false);

				chunk.status = .Ready;
			}
			else {
				chunk.status = .Upload;
			}

			chunk.dirty = false;
		}

		public Vec3f GetSkyColor(Vec3f cameraPos, double tickDelta) {
			float f = GetSkyAngle();
			Vec3f vec3 = (cameraPos - Vec3f(2, 2, 2)) * Vec3f(0.25f, 0.25f, 0.25f);
			Vec3f vec32 = CubicSampler.SampleColor(vec3, scope (x, y, z) => GetBiome(x, y, z).skyColor.ToVec3f());
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

		public Vec4? GetSunriseColor(float timeOfDay) {
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
			// TODO: Need to parse dimension codec
			/*double d = MathHelper.fractionalPart((double)this.fixedTime.orElse(time) / 24000.0 - 0.25);
			double e = 0.5 - Math.cos(d * Math.PI) / 2.0;
			return (float)(d * 2.0 + e) / 3.0f;*/

			
			double d = Utils.FractionalPart(timeOfDay / 24000.0 - 0.25);
			double e = 0.5 - Math.Cos(d * Math.PI_d) / 2.0;
			return (.) (d * 2.0 + e) / 3.0f;
		}

		public float GetCelestialAngle() {
			float f = GetSkyAngle();
			return f * (Math.PI_f * 2);
		}

		public int GetMoonPhase() => (timeOfDay / 24000L % 8L + 8L) % 8;

		public float GetStarBrightness() {
			float f = GetSkyAngle();
			float g = 1 - (Math.Cos(f * (Math.PI_f * 2)) * 2 + 0.25f);
			g = Math.Clamp(g, 0, 1);
			return g * g * 0.5f;
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
				float r = 0.25F + 0.75F * (float)viewDistance / 32.0F;
				r = 1.0F - (float)Math.Pow((double)r, 0.25);
				Vec3f vec3 = GetSkyColor(camera.pos, tickDelta);
				float s = (float)vec3.x;
				float t = (float)vec3.y;
				float u = (float)vec3.z;
				float v = Math.Clamp(Math.Cos(GetSkyAngle() * (float) (Math.PI_f * 2)) * 2.0F + 0.5F, 0.0F, 1.0F);
				Vec3f vec32 = (camera.pos - Vec3f(2, 2, 2)) * Vec3f(0.25f, 0.25f, 0.25f);
				Vec3f vec33 = CubicSampler.SampleColor(vec32, scope (x, y, z) => GetBrightnessDependentFogColor(GetBiome(x, y, z).fogColor.ToVec3f(), v));
				fogRed = (float)vec33.x;
				fogGreen = (float)vec33.y;
				fogBlue = (float)vec33.z;
				if (viewDistance >= 4) {
					float f = Math.Sin(GetSkyAngle()) > 0.0F ? -1.0F : 1.0F;
					Vec3f vector3f = .(f, 0.0F, 0.0F);
					float h = camera.GetDirection(true).Dot(vector3f);
					if (h < 0.0F) {
						h = 0.0F;
					}
	
					if (h > 0.0F) {
						Vec4? sunriseColor = GetSunriseColor(GetSkyAngle());
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

			float r = ((float)camera.pos.y - (float)minY) * 0.03125F; // TODO: Dimension clear color scale
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
}