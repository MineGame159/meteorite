using System;

using Wgpu;

namespace Meteorite {
	static class SkyRenderer {
		private struct PushConstaints1 {
			public Mat4 projectionView;
			public Vec4 color;
		}

		private struct PushConstaints2 {
			public Mat4 projectionView;
			public Vec4 color;
			public Vec4 fogColor;
			public float fogStart, fogEnd;
		}

		private static Pipeline PIPELINE1 ~ delete _;
		private static Pipeline PIPELINE2 ~ delete _;
		private static Pipeline PIPELINE3 ~ delete _;
		private static Pipeline PIPELINE4 ~ delete _;

		private static Mesh MESH1 ~ delete _; // TODO: Uuhhhh
		private static Mesh MESH2 ~ delete _;
		private static Mesh MESH3 ~ delete _;

		private static Mesh LIGHT_MESH ~ delete _;
		private static Mesh DARK_MESH ~ delete _;
		private static Mesh STARS_MESH ~ delete _;

		private static Texture SUN ~ delete _;
		private static Texture MOON ~ delete _;

		private static BindGroup SUN_BIND_GROUP ~ delete _;
		private static BindGroup MOON_BIND_GROUP ~ delete _;

		public static void Init() {
			PIPELINE1 = Gfx.NewPipeline()
				.Attributes(.Float3)
				.VertexShader(Gfxa.POS_FOG, "vs_main")
				.FragmentShader(Gfxa.POS_FOG, "fs_main")
				.PushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints2))
				.Primitive(.TriangleList, false)
				.Blend(false)
				.Depth(true, false) // Dont use depth here
				.Create();
			PIPELINE2 = Gfx.NewPipeline()
				.Attributes(.Float3, .UByte4)
				.VertexShader(Gfxa.POS_COLOR_SHADER, "vs_main")
				.FragmentShader(Gfxa.POS_COLOR_SHADER, "fs_main")
				.PushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints1))
				.Primitive(.TriangleList, false)
				.Depth(true, false) // Dont use depth here
				.Create();
			PIPELINE3 = Gfx.NewPipeline()
				.BindGroupLayouts(Gfxa.TEXTURE_SAMPLER_LAYOUT)
				.Attributes(.Float3, .Float2)
				.VertexShader(Gfxa.POS_TEX_SHADER, "vs_main")
				.FragmentShader(Gfxa.POS_TEX_SHADER, "fs_main")
				.PushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints1))
				.Primitive(.TriangleList, false)
				.BlendState(Wgpu.BlendState() {
					color = .(.Add, .SrcAlpha, .One),
					alpha = .(.Add, .One, .Zero)
				})
				.Depth(true, false) // Dont use depth here
				.Create();
			PIPELINE4 = Gfx.NewPipeline()
				.Attributes(.Float3)
				.VertexShader(Gfxa.POS_FOG, "vs_main")
				.FragmentShader(Gfxa.POS_FOG, "fs_main")
				.PushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints2))
				.Primitive(.TriangleList, false)
				.BlendState(Wgpu.BlendState() {
					color = .(.Add, .SrcAlpha, .One),
					alpha = .(.Add, .One, .Zero)
				})
				.Depth(true, false) // Dont use depth here
				.Create();

			MESH1 = new .();
			MESH2 = new .();
			MESH3 = new .();

			CreateSkyDic(ref LIGHT_MESH, 16);
			CreateSkyDic(ref DARK_MESH, -16);
			CreateStars(ref STARS_MESH);

			SUN = Gfx.CreateTexture("environment/sun.png");
			MOON = Gfx.CreateTexture("environment/moon_phases.png");

			SUN_BIND_GROUP = Gfxa.TEXTURE_SAMPLER_LAYOUT.Create(SUN, Gfxa.NEAREST_SAMPLER);
			MOON_BIND_GROUP = Gfxa.TEXTURE_SAMPLER_LAYOUT.Create(MOON, Gfxa.NEAREST_SAMPLER);
		}

		private static void CreateSkyDic(ref Mesh mesh, float y) {
			mesh = new .();

			float f = Math.Sign(y) * 512.0F; // Uhhh signum?

			mesh.Begin();
			uint32 center = mesh.Vec3(.(0, y, 0)).Next();
			uint32[9] around = .();

			int j = 0;
			for(int i = -180; i <= 180; i += 45) {
				around[j++] = mesh.Vec3(.((f * Math.Cos(i * (Math.PI_f / 180f))), y, (512.0F * Math.Sin(i * (Math.PI_f / 180f))))).Next();
			}

			for (int i < 8) {
				mesh.Triangle(center, around[i], around[i + 1]);
			}

			mesh.End();
		}

		private static void CreateStars(ref Mesh mesh) {
			mesh = new .(Buffers.QUAD_INDICES);
			Random random = scope .();
			mesh.Begin();

			for (int i < 1500) {
				double d = random.NextDouble() * 2 - 1;
				double e = random.NextDouble() * 2 - 1;
				double f = random.NextDouble() * 2 - 1;
				double g = 0.15 + random.NextDouble() * 0.1;
				double h = d * d + e * e + f * f;

				if (h < 1.0 && h > 0.01) {
					h = 1.0 / Math.Sqrt(h);
					d *= h;
					e *= h;
					f *= h;

					double j = d * 100.0;
					double k = e * 100.0;
					double l = f * 100.0;
					double m = Math.Atan2(d, f);
					double n = Math.Sin(m);
					double o = Math.Cos(m);
					double p = Math.Atan2(Math.Sqrt(d * d + f * f), e);
					double q = Math.Sin(p);
					double r = Math.Cos(p);
					double s = random.NextDouble() * Math.PI_d * 2;
					double t = Math.Sin(s);
					double u = Math.Cos(s);

					uint32[4] indices = .();

					for (int v = 0; v < 4; ++v) {
						double x = ((v & 2) - 1) * g;
						double y = (((v + 1) & 2) - 1) * g;
						double aa = x * u - y * t;
						double ab = y * u + x * t;
						double ad = aa * q + 0.0 * r;
						double ae = 0.0 * q - aa * r;
						double af = ae * n - ab * o;
						double ah = ab * n + ae * o;
						indices[v] = mesh.Vec3(.((.) (j + af), (.) (k + ad), (.) (l + ah))).Next();
					}

					mesh.Quad(indices[0], indices[1], indices[2], indices[3]);
				}
			}

			mesh.End();
		}

		public static void Render(World world, Camera camera, double tickDelta) {
			Gfx.PushDebugGroup("Sky");

			Vec3f skyColor = world.GetSkyColor(camera.pos, tickDelta);
			Mat4 baseMatrix = camera.proj * camera.viewRotationOnly;

			PushConstaints1 pc1 = .();
			PushConstaints2 pc2 = .();

			// Light
			PIPELINE1.Bind();
			
			SetupFog(world, ref pc2);
			pc2.projectionView = baseMatrix;
			pc2.color = .(skyColor.x, skyColor.y, skyColor.z, 1);
			Color clearColor = world.GetClearColor(camera, tickDelta);
			pc2.fogColor = .(clearColor.R, clearColor.G, clearColor.B, clearColor.A);
			Gfx.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints2), &pc2);

			LIGHT_MESH.Render();

			// Sunrise
			Vec4? sunriseColor = world.GetSunriseColor(world.GetSkyAngle());
			if (sunriseColor != null) {
				PIPELINE2.Bind();
				pc1.color = .(1, 1, 1, 1);

				Mat4 matrix = .Identity();
				matrix = matrix.Rotate(.(1, 0, 0), 90);
				float angle = Math.Sin(world.GetCelestialAngle()) < 0f ? 180f : 0f;
				matrix = matrix.Rotate(.(0, 0, 1), angle);
				matrix = matrix.Rotate(.(0, 0, 1), 90);
				pc1.projectionView = baseMatrix * matrix;

				Gfx.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints1), &pc1);
				MESH1.Begin();

				Color color = .(sunriseColor.Value.x, sunriseColor.Value.y, sunriseColor.Value.z, sunriseColor.Value.w);
				uint32 center = MESH1.Vec3(.(0, 100, 0)).Color(color).Next();
				uint32[17] around = .();

				color.a = 0;
				for (int i <= 16) {
					float o = (float) i * (Math.PI_f * 2) / 16;
					float p = Math.Sin(o);
					float q = Math.Cos(o);

					around[i] = MESH1.Vec3(.(p * 120, q * 120, -q * 40 * sunriseColor.Value.w)).Color(color).Next();
				}

				for (int i < 16) {
					MESH1.Triangle(center, around[i], around[i + 1]);
				}

				MESH1.End();
				MESH1.Render();
			}

			// Sun
			PIPELINE3.Bind();
			SUN_BIND_GROUP.Bind();

			float alpha = 1.0F - world.GetRainLevel(tickDelta);
			pc1.projectionView = baseMatrix * Mat4.Identity().Rotate(.(0, 1, 0), -90).Rotate(.(1, 0, 0), world.GetSkyAngle() * 360);
			pc1.color = .(1, 1, 1, alpha);
			Gfx.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints1), &pc1);

			float k = 30.0F;
			MESH2.Begin();
			MESH2.Quad(
				MESH2.Vec3(.(-k, 100, -k)).Vec2(.(0, 0)).Next(),
				MESH2.Vec3(.(k, 100, -k)).Vec2(.(1, 0)).Next(),
				MESH2.Vec3(.(k, 100, k)).Vec2(.(1, 1)).Next(),
				MESH2.Vec3(.(-k, 100, k)).Vec2(.(0, 1)).Next()
			);
			MESH2.End();
			MESH2.Render();

			// Moon
			MOON_BIND_GROUP.Bind();

			k = 20.0F;
			int r = world.GetMoonPhase();
			int s = r % 4;
			int m = r / 4 % 2;
			float t = (s + 0) / 4f;
			float o = (m + 0) / 2f;
			float p = (s + 1) / 4f;
			float q = (m + 1) / 2f;

			MESH3.Begin();
			MESH3.Quad(
				MESH3.Vec3(.(-k, -100, k)).Vec2(.(p, q)).Next(),
				MESH3.Vec3(.(k, -100, k)).Vec2(.(t, q)).Next(),
				MESH3.Vec3(.(k, -100, -k)).Vec2(.(t, o)).Next(),
				MESH3.Vec3(.(-k, -100, -k)).Vec2(.(p, o)).Next()
			);
			MESH3.End();
			MESH3.Render();

			// Stars
			float u = world.GetStarBrightness() * alpha;
			if (u > 0) {
				PIPELINE4.Bind();

				pc2.fogStart = float.MaxValue;
				pc2.color = .(u, u, u, u);
				Gfx.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints2), &pc2);

				STARS_MESH.Render();
			}

			// Dark
			//double d = this.minecraft.player.getEyePosition(partialTick).y - this.level.getLevelData().getHorizonHeight(this.level); // TODO
			double d = camera.pos.y + world.minY - 63;
			if (d < 0.0) {
				PIPELINE1.Bind();

				SetupFog(world, ref pc2);
				pc2.projectionView = baseMatrix * Mat4.Identity().Translate(.(0, 12, 0));
				pc2.color = .(0, 0, 0, 1);
				Gfx.SetPushConstants(.Vertex | .Fragment, 0, sizeof(PushConstaints2), &pc2);

				DARK_MESH.Render();
			}

			Gfx.PopDebugGroup();
		}

		private static void SetupFog(World world, ref PushConstaints2 pc) {
			pc.fogStart = 0;
			pc.fogEnd = world.viewDistance;
		}
	}
}