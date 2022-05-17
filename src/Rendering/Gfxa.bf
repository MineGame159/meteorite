using System;

namespace Meteorite {
	[CRepr]
	struct ChunkPushConstants {
		public Mat4 projectionView;
		public Vec2 chunkPos;
	}

	static class Gfxa {
		// Bind group layouts
		public static BindGroupLayout TEXTURE_SAMPLER_LAYOUT ~ delete _;

		// Shaders
		public static Shader CHUNK_SHADER ~ delete _;
		public static Shader CHUNK_TRANSPARENT_SHADER ~ delete _;
		public static Shader LINES_SHADER ~ delete _;
		public static Shader QUADS_SHADER ~ delete _;

		// Pipelines
		public static Pipeline CHUNK_PIPELINE ~ delete _;
		public static Pipeline CHUNK_TRANSPARENT_PIPELINE ~ delete _;
		public static Pipeline QUADS_PIPELINE ~ delete _;
		public static Pipeline LINES_PIPELINE ~ delete _;

		// Samplers
		public static Sampler CHUNK_SAMPLER ~ delete _;
		public static Sampler CHUNK_MIPMAP_SAMPLER ~ delete _;

		// Bind groups
		public static BindGroup CHUNK_BIND_GROUP ~ delete _;
		public static BindGroup CHUNK_MIPMAP_BIND_GROUP ~ delete _;

		// Init
		public static void Init() {
			// Bind group layouts
			TEXTURE_SAMPLER_LAYOUT = Gfx.NewBindGroupLayout()
				.Texture()
				.Sampler(.Filtering)
				.Create();

			// Shaders
			CHUNK_SHADER = Gfx.CreateShader("assets/shaders/chunk.wgsl");
			CHUNK_TRANSPARENT_SHADER = Gfx.CreateShader("assets/shaders/chunkTransparent.wgsl");
			QUADS_SHADER = Gfx.CreateShader("assets/shaders/lines.wgsl");
			LINES_SHADER = Gfx.CreateShader("assets/shaders/lines.wgsl");

			// Pipelines
			CHUNK_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(TEXTURE_SAMPLER_LAYOUT)
				.Attributes(.Float3, .Float2, .UByte4)
				.VertexShader(CHUNK_SHADER, "vs_main")
				.FragmentShader(CHUNK_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(ChunkPushConstants))
				.Primitive(.TriangleList, true)
				.Depth(true)
				.Create();
			CHUNK_TRANSPARENT_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(TEXTURE_SAMPLER_LAYOUT)
				.Attributes(.Float3, .Float2, .UByte4)
				.VertexShader(CHUNK_TRANSPARENT_SHADER, "vs_main")
				.FragmentShader(CHUNK_TRANSPARENT_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(ChunkPushConstants))
				.Primitive(.TriangleList, false)
				.Depth(true, false)
				.Create();
			LINES_PIPELINE = Gfx.NewPipeline()
				.Attributes(.Float3, .UByte4)
				.VertexShader(LINES_SHADER, "vs_main")
				.FragmentShader(LINES_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(Mat4))
				.Primitive(.LineList, true)
				.Depth(true)
				.Create();
			QUADS_PIPELINE = Gfx.NewPipeline()
				.Attributes(.Float3, .UByte4)
				.VertexShader(LINES_SHADER, "vs_main")
				.FragmentShader(LINES_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(Mat4))
				.Primitive(.TriangleList, true)
				.Depth(true)
				.Create();

			// Samplers
			CHUNK_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Nearest, .Nearest);
			CHUNK_MIPMAP_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Nearest, .Nearest, .Linear, 4);

			// Bind groups
			CHUNK_BIND_GROUP = TEXTURE_SAMPLER_LAYOUT.Create(Blocks.ATLAS, CHUNK_SAMPLER);
			CHUNK_MIPMAP_BIND_GROUP = TEXTURE_SAMPLER_LAYOUT.Create(Blocks.ATLAS, CHUNK_MIPMAP_SAMPLER);
		}
	}
}