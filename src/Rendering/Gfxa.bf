using System;

namespace Meteorite {
	[CRepr]
	struct ChunkPushConstants {
		public Mat4 projectionView;
		public Vec3f chunkPos;
	}

	static class Gfxa {
		// Bind group layouts
		public static BindGroupLayout TEXTURE_SAMPLER_LAYOUT ~ delete _;
		public static BindGroupLayout BUFFER_SAMPLER_LAYOUT ~ delete _;

		// Shaders
		public static Shader CHUNK_SHADER ~ delete _;
		public static Shader CHUNK_TRANSPARENT_SHADER ~ delete _;
		public static Shader POS_FOG ~ delete _;
		public static Shader POS_COLOR_SHADER ~ delete _;
		public static Shader POS_TEX_SHADER ~ delete _;

		// Pipelines
		public static Pipeline CHUNK_PIPELINE ~ delete _;
		public static Pipeline CHUNK_TRANSPARENT_PIPELINE ~ delete _;
		public static Pipeline QUADS_PIPELINE ~ delete _;
		public static Pipeline LINES_PIPELINE ~ delete _;

		// Samplers
		public static Sampler NEAREST_SAMPLER ~ delete _;
		public static Sampler NEAREST_MIPMAP_SAMPLER ~ delete _;

		// Init
		public static void Init() {
			// Bind group layouts
			TEXTURE_SAMPLER_LAYOUT = Gfx.NewBindGroupLayout()
				.Texture()
				.Sampler(.Filtering)
				.Create();
			BUFFER_SAMPLER_LAYOUT = Gfx.NewBindGroupLayout()
				.Buffer(.ReadOnlyStorage)
				.Create();

			// Shaders
			CHUNK_SHADER = Gfx.CreateShader("shaders/chunk.wgsl");
			CHUNK_TRANSPARENT_SHADER = Gfx.CreateShader("shaders/chunkTransparent.wgsl");
			POS_FOG = Gfx.CreateShader("shaders/pos_fog.wgsl");
			POS_COLOR_SHADER = Gfx.CreateShader("shaders/pos_color.wgsl");
			POS_TEX_SHADER = Gfx.CreateShader("shaders/pos_tex.wgsl");

			// Pipelines
			CHUNK_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(TEXTURE_SAMPLER_LAYOUT, BUFFER_SAMPLER_LAYOUT)
				.Attributes(.Float3, .UShort2Float, .UByte4, .UShort2)
				.VertexShader(CHUNK_SHADER, "vs_main")
				.FragmentShader(CHUNK_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(ChunkPushConstants))
				.Primitive(.TriangleList, true)
				.Depth(true)
				.Create();
			CHUNK_TRANSPARENT_PIPELINE = Gfx.NewPipeline()
				.BindGroupLayouts(TEXTURE_SAMPLER_LAYOUT, BUFFER_SAMPLER_LAYOUT)
				.Attributes(.Float3, .UShort2Float, .UByte4, .UShort2)
				.VertexShader(CHUNK_TRANSPARENT_SHADER, "vs_main")
				.FragmentShader(CHUNK_TRANSPARENT_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(ChunkPushConstants))
				.Primitive(.TriangleList, true)
				.Depth(true, true, false)
				.Create();
			LINES_PIPELINE = Gfx.NewPipeline()
				.Attributes(.Float3, .UByte4)
				.VertexShader(POS_COLOR_SHADER, "vs_main")
				.FragmentShader(POS_COLOR_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(Mat4))
				.Primitive(.LineList, true)
				.Depth(true)
				.Create();
			QUADS_PIPELINE = Gfx.NewPipeline()
				.Attributes(.Float3, .UByte4)
				.VertexShader(POS_COLOR_SHADER, "vs_main")
				.FragmentShader(POS_COLOR_SHADER, "fs_main")
				.PushConstants(.Vertex, 0, sizeof(Mat4))
				.Primitive(.TriangleList, true)
				.Depth(true)
				.Create();

			// Samplers
			NEAREST_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Nearest, .Nearest);
			NEAREST_MIPMAP_SAMPLER = Gfx.CreateSampler(.ClampToEdge, .Nearest, .Nearest, .Linear, 4);
		}
	}
}