using System;

using Wgpu;

namespace Meteorite {
	class SSAO {
		private Texture ssao;
		private Pipeline pipeline ~ delete _;

		private WBuffer samplesBuffer ~ delete _;
		private Texture noiseTexture ~ delete _;

		private BindGroupLayout bindGroupLayout ~ delete _;
		private BindGroup bindGroup ~ delete _;

		public this(Texture ssao) {
			this.ssao = ssao;

			// Bind group layout
			bindGroupLayout = Gfx.NewBindGroupLayout()
				.Buffer(.Uniform)
				.Texture(.UnfilterableFloat)
				.Sampler(.NonFiltering)
				.Create();

			// Pipeline
			pipeline = Gfx.NewPipeline()
				.BindGroupLayouts(Gfxa.UNIFORM_BIND_GROUP_LAYOUT, Gfxa.TEXTURE_BIND_GROUP_LAYOUT, Gfxa.TEXTURE_BIND_GROUP_LAYOUT, bindGroupLayout)
				.Attributes(.Float2, .Float2)
				.Shader("ssao")
				.Primitive(.TriangleList, .Clockwise)
				.Targets(.R8Unorm)
				.Create();

			// Samples
			Vec4[64] samples = .();
			Random random = scope .();

			for (int i < 64) {
				Vec4 sample = Vec4((.) random.NextDouble() * 2f - 1f, (.) random.NextDouble() * 2f - 1f, (.) random.NextDouble(), 0).Normalize() * (float) random.NextDouble();

				float scale = (float) i / 64f; 
				scale = Math.Lerp(0.1f, 1.0f, scale * scale);
				sample *= scale;

				samples[i] = sample;
			}

			samplesBuffer = Gfx.CreateBuffer(.Uniform, sizeof(Vec4[64]), &samples, "SSAO Samples");

			// Noise
			Vec4[16] noise = .();

			for (int i < 16) {
				noise[i] = .((.) random.NextDouble() * 2f - 1f, (.) random.NextDouble() * 2f - 1f, 0, 0);
			}

			noiseTexture = Gfx.CreateTexture(.TextureBinding, 4, 4, 1, &noise, .RGBA32Float, true, Gfxa.NEAREST_REPEAT_SAMPLER);

			// Bind group
			bindGroup = bindGroupLayout.Create(samplesBuffer, noiseTexture, Gfxa.NEAREST_REPEAT_SAMPLER);
		}

		public void Render(Wgpu.CommandEncoder encoder) {
			Meteorite me = .INSTANCE;

			RenderPass pass = RenderPass.Begin(encoder)
				.Color(ssao, .(255, 255, 255))
				.Finish();
			pass.PushDebugGroup("SSAO");

			pipeline.Bind(pass);
			FrameUniforms.Bind(pass);
			me.gameRenderer.mainNormal.Bind(pass, 1);
			me.gameRenderer.mainDepth.Bind(pass, 2);
			bindGroup.Bind(pass, 3);

			MeshBuilder mb = me.frameBuffers.AllocateImmediate(pass);
			mb.Quad(
				mb.Vec2(.(-1, -1)).Vec2(.(0, 1)).Next(),
				mb.Vec2(.(-1, 1)).Vec2(.(0, 0)).Next(),
				mb.Vec2(.(1, 1)).Vec2(.(1, 0)).Next(),
				mb.Vec2(.(1, -1)).Vec2(.(1, 1)).Next()
			);
			mb.Finish();

			pass.PopDebugGroup();
			pass.End();
		}

		public void Bind(RenderPass pass, int index) => ssao.Bind(pass, index);
	}
}