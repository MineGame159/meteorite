using System;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

class SSAO {
	private Attachments attachments;

	private int ssaoI = -1;
	private GpuImage Ssao => attachments.Get(ssaoI);

	public Pipeline pipeline ~ ReleaseAndNullify!(_);

	private GpuBuffer samplesBuffer ~ ReleaseAndNullify!(_);
	private GpuImage noiseTexture ~ ReleaseAndNullify!(_);

	public this(Attachments attachments) {
		this.attachments = attachments;
		this.ssaoI = attachments.CreateColor("SSAO", .R8);

		// Pipeline
		pipeline = Gfx.Pipelines.Create(scope PipelineInfo("SSAO")
			.VertexFormat(PostVertex.FORMAT)
			.Shader(.File("ssao.vert"), .File("ssao.frag"))
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

		samplesBuffer = Gfx.Buffers.Create("SSAO Samples", .Storage, .Mappable, sizeof(Vec4f[64]));
		samplesBuffer.Upload(&samples, samplesBuffer.Size);

		// Noise
		Vec4f[16] noise = .();

		for (int i < 16) {
			noise[i] = .((.) random.NextDouble() * 2f - 1f, (.) random.NextDouble() * 2f - 1f, 0, 0);
		}

		noiseTexture = Gfx.Images.Create("SSAO Noise", .RGBA32, .ColorAttachment, .(4, 4));
		Gfx.Uploads.UploadImage(noiseTexture, &noise);
	}

	[Tracy.Profile]
	public void Render(CommandBuffer cmds) {
		Meteorite me = .INSTANCE;

		using (RenderPass pass = Gfx.RenderPasses.New(cmds, "SSAO")
			.Color(Ssao, .WHITE)
			.Begin())
		{
			pass.Bind(pipeline);
			pass.Bind(0, FrameUniforms.Descriptor);
			pass.Bind(1, me.gameRenderer.MainNormalDescriptor);
			pass.Bind(2, me.gameRenderer.MainDepthDescriptor);
			pass.Bind(3, .Uniform(samplesBuffer), .SampledImage(noiseTexture, Gfxa.NEAREST_REPEAT_SAMPLER));

			MeshBuilder mb = scope .();

			mb.Quad<PostVertex>(
				.(.(-1, -1), .(0, 1)),
				.(.(-1, 1), .(0, 0)),
				.(.(1, 1), .(1, 0)),
				.(.(1, -1), .(1, 1))
			);

			pass.Draw(mb.End());
		}
	}

	public Descriptor Descriptor => .SampledImage(Ssao, Gfxa.NEAREST_SAMPLER);
}