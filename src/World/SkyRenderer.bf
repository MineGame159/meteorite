using System;

using Cacti;
using Cacti.Graphics;

namespace Meteorite {
	static class SkyRenderer {
		[CRepr]
		struct PosVertex : this(Vec3f pos) {
			public static VertexFormat FORMAT = new VertexFormat()
				.Attribute(.Float, 3)
				~ delete _;
		}

		private struct PushConstaints1 {
			public Mat4 projectionView;
			public Vec4f color;
		}

		private struct PushConstaints2 {
			public Mat4 projectionView;
			public Vec4f color;
			public Vec4f fogColor;
			public float fogStart, fogEnd;
		}

		private static Pipeline PIPELINE1;
		private static Pipeline PIPELINE2;
		private static Pipeline PIPELINE3;
		private static Pipeline PIPELINE4;

		private static BuiltMesh LIGHT_MESH;
		private static BuiltMesh DARK_MESH;
		private static BuiltMesh STARS_MESH;

		private static GpuImage SUN;
		private static GpuImage MOON;

		private static Descriptor SUN_DESCRIPTOR => .SampledImage(SUN, Gfxa.NEAREST_SAMPLER);
		private static Descriptor MOON_DESCRIPTOR => .SampledImage(MOON, Gfxa.NEAREST_SAMPLER);

		public static void Init() {
			PIPELINE1 = Gfx.Pipelines.Create(scope PipelineInfo("Sky 1")
				.VertexFormat(PosVertex.FORMAT)
				.Shader(.File(Gfxa.POS_FOG_VERT), .File(Gfxa.POS_FOG_FRAG))
				.Cull(.None, .Clockwise)
				.Depth(true, false, false)
				.Targets(
					.(.BGRA, .Disabled())
				)
			);
			PIPELINE2 = Gfx.Pipelines.Create(scope PipelineInfo("Sky 2")
				.VertexFormat(PosColorVertex.FORMAT)
				.Shader(.File(Gfxa.POS_COLOR_VERT), .File(Gfxa.POS_COLOR_FRAG))
				.Cull(.None, .Clockwise)
				.Depth(true, false, false)
				.Targets(
					.(.BGRA, .Default())
				)
			);
			PIPELINE3 = Gfx.Pipelines.Create(scope PipelineInfo("Sky 3")
				.VertexFormat(PosUVVertex.FORMAT)
				.Shader(.File(Gfxa.POS_TEX_VERT), .File(Gfxa.POS_TEX_FRAG))
				.Cull(.None, .Clockwise)
				.Depth(true, false, false)
				.Targets(
					.(.BGRA, .Enabled(.(.Add, .SrcAlpha, .One), .(.Add, .One, .Zero)))
				)
			);
			PIPELINE4 = Gfx.Pipelines.Create(scope PipelineInfo("Sky 4")
				.VertexFormat(PosVertex.FORMAT)
				.Shader(.File(Gfxa.POS_FOG_VERT), .File(Gfxa.POS_FOG_FRAG))
				.Cull(.None, .Clockwise)
				.Depth(true, false, false)
				.Targets(
					.(.BGRA, .Enabled(.(.Add, .SrcAlpha, .One), .(.Add, .One, .Zero)))
				)
			);

			CreateSkyDisc(ref LIGHT_MESH, 16);
			CreateSkyDisc(ref DARK_MESH, -16);
			CreateStars(ref STARS_MESH);

			SUN = Gfxa.CreateImage("environment/sun.png");
			MOON = Gfxa.CreateImage("environment/moon_phases.png");
		}

		public static void Destroy() {
			ReleaseAndNullify!(PIPELINE1);
			ReleaseAndNullify!(PIPELINE2);
			ReleaseAndNullify!(PIPELINE3);
			ReleaseAndNullify!(PIPELINE4);

			LIGHT_MESH.Dispose();
			DARK_MESH.Dispose();
			STARS_MESH.Dispose();

			ReleaseAndNullify!(SUN);
			ReleaseAndNullify!(MOON);
		}

		private static void CreateSkyDisc(ref BuiltMesh mesh, float y) {
			float f = Math.Sign(y) * 512.0F; // Uhhh signum?

			MeshBuilder mb = scope .();
			uint32 center = mb.Vertex<PosVertex>(.(.(0, y, 0)));
			uint32[9] around = .();

			int j = 0;
			for(int i = -180; i <= 180; i += 45) {
				around[j++] = mb.Vertex<PosVertex>(.(.(f * Math.Cos(i * (Math.PI_f / 180f)), y, (512.0F * Math.Sin(i * (Math.PI_f / 180f))))));
			}

			for (int i < 8) {
				mb.Triangle(center, around[i], around[i + 1]);
			}

			StringView name = scope $"Sky Disc {y}";
			mesh = mb.End(.Create(name), .Create(name));
		}

		private static void CreateStars(ref BuiltMesh mesh) {
			Random random = scope .();
			MeshBuilder mb = scope .(false);

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
						indices[v] = mb.Vertex<PosVertex>(.(.((.) (j + af), (.) (k + ad), (.) (l + ah))));
					}

					mb.Quad(indices[0], indices[1], indices[2], indices[3]);
				}
			}

			mesh = mb.End(.Create("Sky Stars"), Buffers.QUAD_INDICES);
		}
		
		[Tracy.Profile]
		public static void Render(RenderPass pass, World world, Camera camera, double tickDelta) {
			pass.PushDebugGroup("Sky");

			Vec3f skyColor = world.GetSkyColor(camera.pos.ToFloat, tickDelta);
			Mat4 baseMatrix = camera.proj * camera.viewRotationOnly;

			PushConstaints1 pc1 = .();
			PushConstaints2 pc2 = .();

			// Light
			pass.Bind(PIPELINE1);
			
			SetupFog(world, ref pc2);
			pc2.projectionView = baseMatrix;
			pc2.color = .(skyColor.x, skyColor.y, skyColor.z, 1);
			Color clearColor = world.GetClearColor(camera, tickDelta);
			pc2.fogColor = .(clearColor.R, clearColor.G, clearColor.B, clearColor.A);
			pass.SetPushConstants(pc2);
			
			pass.Draw(LIGHT_MESH);

			// Sunrise
			Vec4f? sunriseColor = world.GetSunriseColor(world.GetSkyAngle());
			if (sunriseColor != null) {
				pass.Bind(PIPELINE2);
				pc1.color = .(1, 1, 1, 1);

				Mat4 matrix = .Identity();
				matrix = matrix.Rotate(.(1, 0, 0), 90);
				float angle = Math.Sin(world.GetCelestialAngle()) < 0f ? 180f : 0f;
				matrix = matrix.Rotate(.(0, 0, 1), angle);
				matrix = matrix.Rotate(.(0, 0, 1), 90);
				pc1.projectionView = baseMatrix * matrix;

				pass.SetPushConstants(pc1.projectionView);
				MeshBuilder mb = scope .();

				Color color = .(sunriseColor.Value.x, sunriseColor.Value.y, sunriseColor.Value.z, sunriseColor.Value.w);
				uint32 center = mb.Vertex<PosColorVertex>(.(.(0, 100, 0), color));
				uint32[17] around = .();

				color.a = 0;
				for (int i <= 16) {
					float o = (float) i * (Math.PI_f * 2) / 16;
					float p = Math.Sin(o);
					float q = Math.Cos(o);

					around[i] = mb.Vertex<PosColorVertex>(.(.(p * 120, q * 120, -q * 40 * sunriseColor.Value.w), color));
				}

				for (int i < 16) {
					mb.Triangle(center, around[i], around[i + 1]);
				}

				pass.Draw(mb.End());
			}

			// Sun
			float alpha = 1.0F - world.GetRainLevel(tickDelta);
			{
				pass.Bind(PIPELINE3);
				pass.Bind(0, SUN_DESCRIPTOR);

				pc1.projectionView = baseMatrix * Mat4.Identity().Rotate(.(0, 1, 0), -90).Rotate(.(1, 0, 0), world.GetSkyAngle() * 360);
				pc1.color = .(1, 1, 1, alpha);
				pass.SetPushConstants(pc1);
				
				float k = 30.0F;
				MeshBuilder mb = scope .(false);

				mb.Quad(
					mb.Vertex<PosUVVertex>(.(.(-k, 100, -k), .(0, 0))),
					mb.Vertex<PosUVVertex>(.(.(k, 100, -k), .(1, 0))),
					mb.Vertex<PosUVVertex>(.(.(k, 100, k), .(1, 1))),
					mb.Vertex<PosUVVertex>(.(.(-k, 100, k), .(0, 1)))
				);

				pass.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));
			}

			// Moon
			{
				pass.Bind(0, MOON_DESCRIPTOR);
	
				float k = 20.0F;
				int r = world.GetMoonPhase();
				int s = r % 4;
				int m = r / 4 % 2;
				float t = (s + 0) / 4f;
				float o = (m + 0) / 2f;
				float p = (s + 1) / 4f;
				float q = (m + 1) / 2f;
	
				MeshBuilder mb = scope .(false);

				mb.Quad(
					mb.Vertex<PosUVVertex>(.(.(-k, -100, k), .(p, q))),
					mb.Vertex<PosUVVertex>(.(.(k, -100, k), .(t, q))),
					mb.Vertex<PosUVVertex>(.(.(k, -100, -k), .(t, o))),
					mb.Vertex<PosUVVertex>(.(.(-k, -100, -k), .(p, o)))
				);

				pass.Draw(mb.End(.Frame, Buffers.QUAD_INDICES));
	
				// Stars
				float u = world.GetStarBrightness() * alpha;
				if (u > 0) {
					pass.Bind(PIPELINE4);
	
					pc2.fogStart = float.MaxValue;
					pc2.color = .(u, u, u, u);
					pass.SetPushConstants(pc2);

					pass.Draw(STARS_MESH);
				}
			}

			// Dark
			//double d = this.minecraft.player.getEyePosition(partialTick).y - this.level.getLevelData().getHorizonHeight(this.level); // TODO
			double d = camera.pos.y + world.dimension.minY - 63;
			if (d < 0.0) {
				pass.Bind(PIPELINE1);

				SetupFog(world, ref pc2);
				pc2.projectionView = baseMatrix * Mat4.Identity().Translate(.(0, 12, 0));
				pc2.color = .(0, 0, 0, 1);
				pass.SetPushConstants(pc2);

				pass.Draw(DARK_MESH);
			}

			pass.PopDebugGroup();
		}

		private static void SetupFog(World world, ref PushConstaints2 pc) {
			pc.fogStart = 0;
			pc.fogEnd = Meteorite.INSTANCE.options.renderDistance;
		}
	}
}