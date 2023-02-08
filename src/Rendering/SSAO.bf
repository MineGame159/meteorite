using System;

using Cacti;

namespace Meteorite {
	class SSAO {
		private GpuImage ssao;
		public Pipeline pipeline;

		private GpuBuffer samplesBuffer ~ delete _;
		private GpuImage noiseTexture ~ delete _;

		private DescriptorSet set ~ delete _;
		private DescriptorSet ssaoSet ~ delete _;

		public this(GpuImage ssao) {
			this.ssao = ssao;
			this.ssaoSet = Gfx.DescriptorSets.Create(Gfxa.IMAGE_SET_LAYOUT, .SampledImage(ssao, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.NEAREST_SAMPLER));

			DescriptorSetLayout setLayout = Gfx.DescriptorSetLayouts.Get(.StorageBuffer, .SampledImage);

			// Pipeline
			pipeline = Gfx.Pipelines.Get(scope PipelineInfo("SSAO")
				.VertexFormat(PostVertex.FORMAT)
				.Sets(Gfxa.UNIFORM_SET_LAYOUT, Gfxa.IMAGE_SET_LAYOUT, Gfxa.IMAGE_SET_LAYOUT, setLayout)
				.Shader("ssao", "ssao")
				.Targets(
					.(.R8, .Disabled())
				)
			);

			// Samples
			Vec4f[64] samples = .();
			Random random = scope .();

			for (int i < 64) {
				Vec4f sample = Vec4f((.) random.NextDouble() * 2f - 1f, (.) random.NextDouble() * 2f - 1f, (.) random.NextDouble(), 0).Normalize() * (float) random.NextDouble();

				float scale = (float) i / 64f; 
				scale = Math.Lerp(0.1f, 1.0f, scale * scale);
				sample *= scale;

				samples[i] = sample;
			}

			samplesBuffer = Gfx.Buffers.Create(.Storage, .Mappable, sizeof(Vec4f[64]), "SSAO Samples");
			samplesBuffer.Upload(&samples, samplesBuffer.size);

			// Noise
			Vec4f[16] noise = .();

			for (int i < 16) {
				noise[i] = .((.) random.NextDouble() * 2f - 1f, (.) random.NextDouble() * 2f - 1f, 0, 0);
			}

			noiseTexture = Gfx.Images.Create(.RGBA32, .ColorAttachment, .(4, 4), "SSAO Noise");
			Gfx.Uploads.UploadImage(noiseTexture, &noise);

			// Bind group
			set = Gfx.DescriptorSets.Create(setLayout, .Storage(samplesBuffer), .SampledImage(noiseTexture, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.NEAREST_REPEAT_SAMPLER));
		}

		public void Render(CommandBuffer cmds) {
			Meteorite me = .INSTANCE;

			cmds.PushDebugGroup("SSAO");
			cmds.TransitionImage(ssao, .ColorAttachment);
			cmds.TransitionImage(me.gameRenderer.mainNormal, .Sample);
			cmds.TransitionImage(me.gameRenderer.mainDepth, .Sample);

			using (RenderPass pass = Gfx.RenderPasses.Begin(cmds, "SSAO", null, .(ssao, .WHITE))) {
				cmds.Bind(pipeline);
				FrameUniforms.Bind(cmds);
				cmds.Bind(me.gameRenderer.mainNormalSet, 1);
				cmds.Bind(me.gameRenderer.mainDepthSet, 2);
				cmds.Bind(set, 3);
	
				MeshBuilder mb = scope .();
	
				mb.Quad<PostVertex>(
					.(.(-1, -1), .(0, 1)),
					.(.(-1, 1), .(0, 0)),
					.(.(1, 1), .(1, 0)),
					.(.(1, -1), .(1, 1))
				);
	
				cmds.Draw(mb.End());
			}
		}

		public void Transition(CommandBuffer cmds) => cmds.TransitionImage(ssao, .Sample);
		public void Bind(CommandBuffer cmds, uint32 index) => cmds.Bind(ssaoSet, index);
	}
}