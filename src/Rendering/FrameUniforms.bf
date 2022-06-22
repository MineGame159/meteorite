using System;

namespace Meteorite {
	static class FrameUniforms {
		[CRepr]
		struct Data {
			public Mat4 projection, view, projectionView;
			public Vec4 resolution; // GLSL: vec2
		}

		private static WBuffer buffer ~ delete _;
		private static BindGroup bindGroup ~ delete _;

		public static void Init() {
			buffer = Gfx.CreateBuffer(.Uniform | .CopyDst, sizeof(Data), null, "Frame Uniforms");
			bindGroup = Gfxa.UNIFORM_BIND_GROUP_LAYOUT.Create(buffer);
		}

		public static void Update() {
			Data data = .();

			Camera camera = Meteorite.INSTANCE.camera;
			data.projection = camera.proj;
			data.view = camera.view;
			data.projectionView = camera.proj * camera.view;

			Window window = Meteorite.INSTANCE.window;
			data.resolution = .(window.width, window.height, 0, 0);

			buffer.Write(&data, sizeof(Data));
		}

		public static void Bind(RenderPass pass) => bindGroup.Bind(pass);
	}
}