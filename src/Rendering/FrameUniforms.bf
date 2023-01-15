using System;

using Cacti;

namespace Meteorite {
	static class FrameUniforms {
		[CRepr]
		struct Data {
			public Mat4 projection, inverseProjection;
			public Mat4 view, inverseView;
			public Mat4 projectionView;

			public float projectionA, projectionB;

			public Vec4f resolution; // GLSL: vec2
		}

		private static GpuBuffer buffer;
		private static DescriptorSet set;

		public static void Init() {
			buffer = Gfx.Buffers.Create(.Uniform, .Mappable, sizeof(Data), "Frame Uniforms");
			set = Gfx.DescriptorSets.Create(Gfxa.UNIFORM_SET_LAYOUT, .Uniform(buffer));
		}

		public static void Destroy() {
			delete buffer;
			delete set;
		}
		
		public static void Update() {
			Data data = .();

			Camera camera = Meteorite.INSTANCE.camera;
			data.projection = camera.proj;
			data.inverseProjection = camera.proj.InverseTranspose();
			data.view = camera.view;
			data.inverseView = camera.view.InverseTranspose();
			data.projectionView = camera.proj * camera.view;

			float nearClipDistance = camera.nearClip;
			float farClipDistance = camera.farClip;
			data.projectionA = farClipDistance / (farClipDistance - nearClipDistance);
			data.projectionB = (-farClipDistance * nearClipDistance) / (farClipDistance - nearClipDistance);

			Window window = Meteorite.INSTANCE.window;
			data.resolution = .(window.Width, window.Height, 0, 0);

			buffer.Upload(&data, sizeof(Data));
		}

		public static void Bind(CommandBuffer cmds) => cmds.Bind(set, 0);
	}
}