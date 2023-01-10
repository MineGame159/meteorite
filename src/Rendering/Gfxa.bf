using System;
using System.IO;

using Cacti;

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

		// Shaders
		public static StringView POS_FOG = "pos_fog";
		public static StringView POS_COLOR_SHADER = "pos_color";
		public static StringView POS_TEX_SHADER = "pos_tex";
		public static StringView POS_TEX_COLOR_SHADER = "pos_tex_color";

		// Pipelines
		public static Pipeline CHUNK_PIPELINE;
		public static Pipeline CHUNK_TRANSPARENT_PIPELINE;
		public static Pipeline ENTITY_PIPELINE;
		public static Pipeline POST_PIPELINE;
		public static Pipeline LINES_PIPELINE;
		public static Pipeline TEX_QUADS_PIPELINE;

		// Samplers
		public static Sampler NEAREST_SAMPLER;
		public static Sampler NEAREST_REPEAT_SAMPLER;
		public static Sampler LINEAR_SAMPLER;
		public static Sampler NEAREST_MIPMAP_SAMPLER;

		// Descriptor set layouts
		public static DescriptorSetLayout UNIFORM_SET_LAYOUT;
		public static DescriptorSetLayout STORAGE_SET_LAYOUT;
		public static DescriptorSetLayout IMAGE_SET_LAYOUT;

		// Descriptor sets
		public static DescriptorSet PIXEL_SET;

		// Init
		public static void Init() {
			Gfx.Pipelines.SetReadCallback(new (path) => {
				String buffer = scope .();
				bool result = Meteorite.INSTANCE.resources.ReadString(scope $"shaders/{path}", buffer);

				if (result) return ShaderReadResult.New(path, buffer);
				return ShaderReadResult.New("", "");
			});

			// Descriptor set layouts
			UNIFORM_SET_LAYOUT = Gfx.DescriptorSetLayouts.Get(.UniformBuffer);
			STORAGE_SET_LAYOUT = Gfx.DescriptorSetLayouts.Get(.StorageBuffer);
			IMAGE_SET_LAYOUT = Gfx.DescriptorSetLayouts.Get(.SampledImage);

			// Pipelines
			CHUNK_PIPELINE = Gfx.Pipelines.New("Chunks")
				.VertexFormat(BlockVertex.FORMAT)
				.Sets(STORAGE_SET_LAYOUT, IMAGE_SET_LAYOUT, STORAGE_SET_LAYOUT)
				.PushConstants<Vec3f>()
				.Shader("chunk", "chunk", new (preProcessor) => preProcessor.Define("SOLID"))
				.Targets(.BGRA, .RGBA16)
				.Depth(true)
				.Create();
			CHUNK_TRANSPARENT_PIPELINE = Gfx.Pipelines.New("Transparent chunks")
				.VertexFormat(BlockVertex.FORMAT)
				.Sets(STORAGE_SET_LAYOUT, IMAGE_SET_LAYOUT, STORAGE_SET_LAYOUT)
				.PushConstants<Vec3f>()
				.Shader("chunk", "chunk")
				.Targets(.BGRA, .RGBA16)
				.Depth(true, true, false)
				.Create();
			ENTITY_PIPELINE = Gfx.Pipelines.New("Entities")
				.VertexFormat(EntityVertex.FORMAT)
				.Sets(STORAGE_SET_LAYOUT, IMAGE_SET_LAYOUT, STORAGE_SET_LAYOUT)
				.Shader("entity", "entity")
				.Targets(.BGRA, .RGBA16)
				.Cull(.Back, .CounterClockwise)
				.Depth(true)
				.Create();
			POST_PIPELINE = Gfx.Pipelines.New("Post")
				.VertexFormat(PostVertex.FORMAT)
				.Sets(STORAGE_SET_LAYOUT, IMAGE_SET_LAYOUT, IMAGE_SET_LAYOUT)
				.Shader("post", "post", new => PostPreProcessor)
				.Cull(.Back, .Clockwise)
				.Create();
			LINES_PIPELINE = Gfx.Pipelines.New("Lines")
				.VertexFormat(PosColorVertex.FORMAT)
				.PushConstants<Mat4>()
				.Shader(POS_COLOR_SHADER, POS_COLOR_SHADER)
				.Primitive(.Lines)
				.Cull(.Back, .Clockwise)
				.Depth(true, false, false)
				.Create();
			TEX_QUADS_PIPELINE = Gfx.Pipelines.New("Textured quads")
				.VertexFormat(Pos2DUVColorVertex.FORMAT)
				.Sets(IMAGE_SET_LAYOUT)
				.PushConstants<Mat4>()
				.Shader(POS_TEX_COLOR_SHADER, POS_TEX_COLOR_SHADER)
				.Cull(.Back, .Clockwise)
				.Create();

			// Samplers
			NEAREST_SAMPLER = Gfx.Samplers.Get(.Nearest, .Nearest);
			NEAREST_REPEAT_SAMPLER = Gfx.Samplers.Get(.Nearest, .Nearest, .Nearest, .Repeat, .Repeat, .Repeat);
			LINEAR_SAMPLER = Gfx.Samplers.Get(.Linear, .Linear);
			NEAREST_MIPMAP_SAMPLER = Gfx.Samplers.Get(.Nearest, .Nearest, .Linear, maxLod:3);

			// Other
			PIXEL_TEXTURE = CreateImage("pixel.png");

			// Descriptor sets
			PIXEL_SET = Gfx.DescriptorSets.Create(IMAGE_SET_LAYOUT, .SampledImage(PIXEL_TEXTURE, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, NEAREST_SAMPLER));
		}

		public static void Destroy() {
			delete PIXEL_TEXTURE;

			delete CHUNK_PIPELINE;
			delete CHUNK_TRANSPARENT_PIPELINE;
			delete ENTITY_PIPELINE;
			delete POST_PIPELINE;
			delete LINES_PIPELINE;
			delete TEX_QUADS_PIPELINE;

			delete PIXEL_SET;
		}

		public static GpuImage CreateImage(StringView path) {
			Image image = Meteorite.INSTANCE.resources.ReadImage(path);
			defer delete image;

			GpuImage gpuImage = Gfx.Images.Create(.RGBA, .Normal, image.size, path);
			gpuImage.Upload(image.pixels);

			return gpuImage;
		}

		private static void PostPreProcessor(ShaderPreProcessor preProcessor) {
			if (Meteorite.INSTANCE.options.fxaa) preProcessor.Define("FXAA");
			if (Meteorite.INSTANCE.options.ao.HasSSAO) preProcessor.Define("SSAO");
		}
	}
}