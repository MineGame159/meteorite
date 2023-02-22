using System;
using System.IO;

using Cacti;
using Cacti.Graphics;

namespace Meteorite {
	[CRepr]
	struct PostVertex : this(Vec2f pos, Vec2f uv) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 2)
			.Attribute(.Float, 2)
			~ delete _;
	}

	[CRepr]
	struct PosColorVertex : this(Vec3f pos, Color color) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 3)
			.Attribute(.U8, 4, true)
			~ delete _;
	}

	[CRepr]
	struct PosUVVertex : this(Vec3f pos, Vec2f uv) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 3)
			.Attribute(.Float, 2)
			~ delete _;
	}

	[CRepr]
	struct PosUVColorVertex : this(Vec3f pos, Vec2f uv, Color color) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 3)
			.Attribute(.Float, 2)
			.Attribute(.U8, 4, true)
			~ delete _;
	}

	[CRepr]
	struct Pos2DUVColorVertex : this(Vec2f pos, Vec2f uv, Color color) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 2)
			.Attribute(.Float, 2)
			.Attribute(.U8, 4, true)
			~ delete _;
	}

	static class Gfxa {
		private static GpuImage PIXEL_TEXTURE;

		public static Descriptor PIXEL_DESCRIPTOR => .SampledImage(PIXEL_TEXTURE, NEAREST_SAMPLER);

		// Shaders
		public static StringView POS_FOG_VERT = "pos_fog.vert";
		public static StringView POS_FOG_FRAG = "pos_fog.frag";

		public static StringView POS_COLOR_VERT = "pos_color.vert";
		public static StringView POS_COLOR_FRAG = "pos_color.frag";

		public static StringView POS_TEX_VERT = "pos_tex.vert";
		public static StringView POS_TEX_FRAG = "pos_tex.frag";

		public static StringView POS_TEX_COLOR_VERT = "pos_tex_color.vert";
		public static StringView POS_TEX_COLOR_FRAG = "pos_tex_color.frag";

		// Pipelines
		public static Pipeline CHUNK_PIPELINE;
		public static Pipeline CHUNK_TRANSPARENT_PIPELINE;
		public static Pipeline ENTITY_PIPELINE;
		public static Pipeline POST_PIPELINE;
		public static Pipeline SMAA_EDGE_DETECTION_PIPELINE;
		public static Pipeline SMAA_BLENDING_PIPELINE;
		public static Pipeline LINES_PIPELINE;
		public static Pipeline TEX_QUADS_PIPELINE;

		// Samplers
		public static Sampler NEAREST_SAMPLER;
		public static Sampler NEAREST_REPEAT_SAMPLER;
		public static Sampler LINEAR_SAMPLER;
		public static Sampler NEAREST_MIPMAP_SAMPLER;

		// Init
		public static void Init() {
			Gfx.Shaders.SetReadCallback(new (path, output) => {
				bool result = Meteorite.INSTANCE.resources.ReadString(scope $"shaders/{path}", output);
				return result ? .Ok : .Err;
			});

			// Pipelines
			CHUNK_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("Chunks")
				.VertexFormat(BlockVertex.FORMAT)
				.Shader(.File("chunk.vert"), .File("chunk.frag"), new (preProcessor) => preProcessor.Define("SOLID"))
				.Depth(true, true, true)
				.Targets(
					.(.BGRA, .Disabled()),
					.(.RGBA16, .Disabled())
				)
			);
			CHUNK_TRANSPARENT_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("Transparent chunks")
				.VertexFormat(BlockVertex.FORMAT)
				.Shader(.File("chunk.vert"), .File("chunk.frag"))
				.Depth(true, true, false)
				.Targets(
					.(.BGRA, .Default()),
					.(.RGBA16, .Disabled())
				)
			);
			ENTITY_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("Entities")
				.VertexFormat(EntityVertex.FORMAT)
				.Shader(.File("entity.vert"), .File("entity.frag"))
				.Depth(true, true, true)
				.Targets(
					.(.BGRA, .Disabled()),
					.(.RGBA16, .Disabled())
				)
			);
			POST_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("Post")
				.VertexFormat(PostVertex.FORMAT)
				.Shader(.File("post.vert"), .File("post.frag"), new => PostPreProcessor)
				.Targets(
					.(.BGRA, .Disabled())
				)
			);
			SMAA_EDGE_DETECTION_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("SMAA - Edge Detection")
				.VertexFormat(PostVertex.FORMAT)
				.Shader(.File("smaa/edge_detection.vert"), .File("smaa/edge_detection.frag"), new => SMAAPreProcessor)
				.Targets(
					.(.RG8, .Disabled())
				)
			);
			SMAA_BLENDING_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("SMAA - Blending")
				.VertexFormat(PostVertex.FORMAT)
				.Shader(.File("smaa/blending.vert"), .File("smaa/blending.frag"), new => SMAAPreProcessor)
				.Targets(
					.(.BGRA, .Disabled())
				)
			);
			LINES_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("Lines")
				.VertexFormat(PosColorVertex.FORMAT)
				.Shader(.File(POS_COLOR_VERT), .File(POS_COLOR_FRAG))
				.Primitive(.Lines)
				.Depth(true, false, false)
				.Targets(
					.(.BGRA, .Default())
				)
			);
			TEX_QUADS_PIPELINE = Gfx.Pipelines.Create(scope PipelineInfo("Textured quads")
				.VertexFormat(Pos2DUVColorVertex.FORMAT)
				.Shader(.File(POS_TEX_COLOR_VERT), .File(POS_TEX_COLOR_FRAG))
				.Targets(
					.(.BGRA, .Default())
				)
			);

			// Samplers
			NEAREST_SAMPLER = Gfx.Samplers.Get(.Nearest, .Nearest);
			NEAREST_REPEAT_SAMPLER = Gfx.Samplers.Get(.Nearest, .Nearest, .Nearest, .Repeat, .Repeat, .Repeat);
			LINEAR_SAMPLER = Gfx.Samplers.Get(.Linear, .Linear);
			NEAREST_MIPMAP_SAMPLER = Gfx.Samplers.Get(.Nearest, .Nearest, .Linear, maxLod:3);

			// Other
			PIXEL_TEXTURE = CreateImage("pixel.png");
		}

		public static void Destroy() {
			ReleaseAndNullify!(PIXEL_TEXTURE);

			ReleaseAndNullify!(CHUNK_PIPELINE);
			ReleaseAndNullify!(CHUNK_TRANSPARENT_PIPELINE);
			ReleaseAndNullify!(ENTITY_PIPELINE);
			ReleaseAndNullify!(POST_PIPELINE);
			ReleaseAndNullify!(SMAA_EDGE_DETECTION_PIPELINE);
			ReleaseAndNullify!(SMAA_BLENDING_PIPELINE);
			ReleaseAndNullify!(LINES_PIPELINE);
			ReleaseAndNullify!(TEX_QUADS_PIPELINE);
		}

		public static GpuImage CreateImage(StringView path, bool flip = false) {
			Image image = Meteorite.INSTANCE.resources.ReadImage(path, flip);
			defer delete image;

			GpuImage gpuImage = Gfx.Images.Create(path, .RGBA, .Normal, image.size);
			Gfx.Uploads.UploadImage(gpuImage, image.pixels);

			return gpuImage;
		}

		private static void PostPreProcessor(ShaderPreProcessOptions preProcessor) {
			if (Meteorite.INSTANCE.options.aa.enabled) preProcessor.Define("SMAA_ENABLED");
			if (Meteorite.INSTANCE.options.ao.HasSSAO) preProcessor.Define("SSAO_ENABLED");

			SMAAPreProcessor(preProcessor);
		}

		private static void SMAAPreProcessor(ShaderPreProcessOptions preProcessor) {
			AAOptions options = Meteorite.INSTANCE.options.aa;

			// Edge detection
			switch (options.edgeDetection) {
			case .Fast:		preProcessor.Define("SMAA_EDGE_DETECTION_LUMA");
			case .Fancy:	preProcessor.Define("SMAA_EDGE_DETECTION_COLOR");
			}

			// Quality
			switch (options.quality) {
			case .Fast:		preProcessor.Define("SMAA_PRESET_MEDIUM");
			case .Balanced:	preProcessor.Define("SMAA_PRESET_HIGH");
			case .Fancy:	preProcessor.Define("SMAA_PRESET_ULTRA");
			}
		}
	}
}