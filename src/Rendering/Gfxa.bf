using System;

namespace Meteorite {
	static class Gfxa {
		private static Texture PIXEL_TEXTURE ~ delete _;

		// Bind group layouts
		public static BindGroupLayout UNIFORM_BIND_GROUP_LAYOUT ~ delete _;
		public static BindGroupLayout TEXTURE_BIND_GROUP_LAYOUT ~ delete _;
		public static BindGroupLayout TEXTURE_BIND_GROUP_LAYOUT2 ~ delete _;
		public static BindGroupLayout BUFFER_BIND_GROUP_LAYOUT ~ delete _;

		// Shaders
		public static StringView POS_FOG = "pos_fog";
		public static StringView POS_COLOR_SHADER = "pos_color";
		public static StringView POS_TEX_SHADER = "pos_tex";
		public static StringView POS_TEX_COLOR_SHADER = "pos_tex_color";

		// Pipelines
		public static Pipeline CHUNK_PIPELINE ~ delete _;
		public static Pipeline CHUNK_TRANSPARENT_PIPELINE ~ delete _;
		public static Pipeline ENTITY_PIPELINE ~ delete _;
		public static Pipeline POST_PIPELINE ~ delete _;
		public static Pipeline LINES_PIPELINE ~ delete _;
		public static Pipeline TEX_QUADS_PIPELINE ~ delete _;

		// Samplers
		public static Sampler NEAREST_SAMPLER ~ delete _;
		public static Sampler NEAREST_REPEAT_SAMPLER ~ delete _;
		public static Sampler LINEAR_SAMPLER ~ delete _;
		public static Sampler NEAREST_MIPMAP_SAMPLER ~ delete _;

		// Bind Groups
		public static BindGroup PIXEL_BIND_GRUP ~ delete _;

		// Init
		public static void Init() {
			// Bind group layouts
			UNIFORM_BIND_GROUP_LAYOUT = Gfx.NewBindGroupLayout()
				.Buffer(.Uniform)
				.Create();
			TEXTURE_BIND_GROUP_LAYOUT = Gfx.NewBindGroupLayout()
				.Texture()
				.Sampler(.Filtering)
				.Create();
			TEXTURE_BIND_GROUP_LAYOUT2 = Gfx.NewBindGroupLayout()
				.Texture(.UnfilterableFloat)
				.Sampler(.NonFiltering)
				.Create();
			BUFFER_BIND_GROUP_LAYOUT = Gfx.NewBindGroupLayout()
				.Buffer(.Storage)
				.Create();

			// Pipelines
			CHUNK_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(UNIFORM_BIND_GROUP_LAYOUT, TEXTURE_BIND_GROUP_LAYOUT, BUFFER_BIND_GROUP_LAYOUT)
				.Attributes(.Float3, .UShort2Float, .UByte4, .UShort2, .SByte4)
				.Shader("chunk", new (preProcessor) => preProcessor.Define("SOLID"))
				.PushConstants(.Vertex, 0, sizeof(Vec3f))
				.Primitive(.TriangleList, .Clockwise)
				.Targets(.BGRA8Unorm, .RGBA16Float)
				.Depth(true)
				.Create();
			CHUNK_TRANSPARENT_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(UNIFORM_BIND_GROUP_LAYOUT, TEXTURE_BIND_GROUP_LAYOUT, BUFFER_BIND_GROUP_LAYOUT)
				.Attributes(.Float3, .UShort2Float, .UByte4, .UShort2, .SByte4)
				.Shader("chunk")
				.PushConstants(.Vertex, 0, sizeof(Vec3f))
				.Primitive(.TriangleList, .Clockwise)
				.Targets(.BGRA8Unorm, .RGBA16Float)
				.Depth(true, true, false)
				.Create();
			ENTITY_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(UNIFORM_BIND_GROUP_LAYOUT, TEXTURE_BIND_GROUP_LAYOUT, BUFFER_BIND_GROUP_LAYOUT)
				.Attributes(.Float3, .SByte4, .UShort2Float, .UByte4)
				.Shader("entity")
				.Primitive(.TriangleList, .Clockwise)
				.Targets(.BGRA8Unorm, .RGBA16Float)
				.Depth(true)
				.Create();
			POST_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(UNIFORM_BIND_GROUP_LAYOUT, TEXTURE_BIND_GROUP_LAYOUT, TEXTURE_BIND_GROUP_LAYOUT)
				.Attributes(.Float2, .Float2)
				.Shader("post", new => PostPreProcessor)
				.Primitive(.TriangleList, .Clockwise)
				.Create();
			LINES_PIPELINE = Gfx.NewPipeline()
				.Attributes(.Float3, .UByte4)
				.Shader(POS_COLOR_SHADER)
				.PushConstants(.Vertex, 0, sizeof(Mat4))
				.Primitive(.LineList, .Clockwise)
				.Depth(true, false, false)
				.Create();
			TEX_QUADS_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(TEXTURE_BIND_GROUP_LAYOUT)
				.Attributes(.Float2, .Float2, .UByte4)
				.Shader(POS_TEX_COLOR_SHADER)
				.PushConstants(.Vertex, 0, sizeof(Mat4))
				.Primitive(.TriangleList, .Clockwise)
				.Create();

			// Samplers
			NEAREST_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Nearest, .Nearest);
			NEAREST_REPEAT_SAMPLER = Gfx.CreateSampler(.Repeat, .Nearest, .Nearest);
			LINEAR_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Linear, .Linear);
			NEAREST_MIPMAP_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Nearest, .Nearest, .Linear, 4);

			// Other
			PIXEL_TEXTURE = Gfx.CreateTexture("pixel.png");

			// Bind Groups
			PIXEL_BIND_GRUP = TEXTURE_BIND_GROUP_LAYOUT.Create(PIXEL_TEXTURE, NEAREST_SAMPLER);
		}

		private static void PostPreProcessor(ShaderPreProcessor preProcessor) {
			if (Meteorite.INSTANCE.options.fxaa) preProcessor.Define("FXAA");
			if (Meteorite.INSTANCE.options.ao.HasSSAO) preProcessor.Define("SSAO");
		}
	}
}