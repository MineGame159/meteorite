using System;

using Cacti;
using Cacti.Graphics;

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

		public static void Init() {
			buffer = Gfx.Buffers.Create("Frame Uniforms", .Uniform, .Mappable, sizeof(Data));
		}

		public static void Destroy() {
			ReleaseAndNullify!(buffer);
		}
		
		[Tracy.Profile]
		public static void Update() {
			Data data = .();

			Camera camera = Meteorite.INSTANCE.camera;
			data.projection = camera.proj;
			data.inverseProjection = camera.proj.InverseTranspose();
			data.view = camera.viewRotationOnly;
			data.inverseView = camera.viewRotationOnly.InverseTranspose();
			data.projectionView = camera.proj * camera.viewRotationOnly;

			float nearClipDistance = camera.nearClip;
			float farClipDistance = camera.farClip;
			data.projectionA = farClipDistance / (farClipDistance - nearClipDistance);
			data.projectionB = (-farClipDistance * nearClipDistance) / (farClipDistance - nearClipDistance);

			Window window = Meteorite.INSTANCE.window;
			data.resolution = .(window.Width, window.Height, 0, 0);

			buffer.Upload(&data, sizeof(Data));
		}

		public static Descriptor Descriptor => .Uniform(buffer);
	}
}