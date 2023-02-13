using System;
using System.Collections;

using Cacti;
using Cacti.Graphics;

using ImGui;

namespace Meteorite;

class CactiTest : Application {
	private const String VERTEX_SHADER = """
		#version 460

		layout (location = 0) in vec3 pos;
		layout (location = 1) in vec3 normal;
		layout (location = 2) in vec4 color;

		layout (set = 0, binding = 0) uniform Uniforms {
			mat4 projection;
			mat4 view;
		};

		layout (location = 0) out vec3 v_Normal;
		layout (location = 1) out vec4 v_Color;

		void main() {
			gl_Position = projection * view * vec4(pos, 1.0);

			v_Normal = normal;
			v_Color = color;
		}
		""";

	private const String FRAGMENT_SHADER = """
		#version 460

		layout (location = 0) out vec4 color;
		layout (location = 1) out vec4 normal;
		
		layout (location = 0) in vec3 v_Normal;
		layout (location = 1) in vec4 v_Color;

		void main() {
			color = v_Color;
			normal = vec4(v_Normal, 0.0);
		}
		""";

	[CRepr]
	struct Uniforms {
		public Mat4 projection;
		public Mat4 view;
	}

	[CRepr]
	struct Vertex : this(Vec3f pos, Vec3f normal, Color color) {
		public static VertexFormat FORMAT = new VertexFormat()
			.Attribute(.Float, 3)
			.Attribute(.Float, 3)
			.Attribute(.U8, 4, true)
			~ delete _;
	}

	private GpuImage depth ~ ReleaseAndNullify!(_);
	private GpuImage normal ~ ReleaseAndNullify!(_);

	private Pipeline pipeline ~ ReleaseAndNullify!(_);

	private GpuBuffer ubo ~ ReleaseAndNullify!(_);

	private Camera camera ~ delete _;

	public this() : base("Cacti Test") {
		depth = Gfx.Images.Create("Depth", .Depth, .DepthAttachment, window.size);
		normal = Gfx.Images.Create("Normal", .RGBA32, .ColorAttachment, window.size);

		pipeline = Gfx.Pipelines.Create(scope PipelineInfo("Yoo")
			.VertexFormat(Vertex.FORMAT)
			.Primitive(.Traingles)
			.Shader(.String(VERTEX_SHADER), .String(FRAGMENT_SHADER))
			.Cull(.None, .Clockwise)
			.Depth(true, true, true)
			.Targets(
				.(.BGRA, .Default()),
				.(.RGBA32, .Disabled())
			)
		);

		ubo = Gfx.Buffers.Create("UBO", .Uniform, .Mappable, sizeof(Uniforms));

		camera = new .(window);
		camera.pos = .(5, 8, -3);
		camera.yaw = -90;
	}

	[Tracy.Profile]
	protected override void Update(double delta) {
		if (Input.IsKeyReleased(.Escape)) window.MouseHidden = !window.MouseHidden;

		camera.FlightMovement((.) delta);
		camera.Update(1000);
	}
	
	[Tracy.Profile]
	protected override void Render(List<CommandBuffer> commandBuffers, GpuImage target, double delta) {
		UploadUniforms();
		ResizeAttachments();

		CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
		commandBuffers.Add(cmds);

		cmds.Begin();
		RenderScene(cmds, target);
		cmds.End();

		RenderUI();
	}
	
	[Tracy.Profile]
	private void UploadUniforms() {
		Uniforms uniforms = .();

		uniforms.projection = camera.proj;
		uniforms.view = camera.view;

		ubo.Upload(&uniforms, ubo.Size);
	}
	
	[Tracy.Profile]
	private void ResizeAttachments() {
		Gfx.Images.Resize(ref depth, window.size);
		Gfx.Images.Resize(ref normal, window.size);
	}
	
	[Tracy.Profile]
	private void RenderScene(CommandBuffer cmds, GpuImage target) {
		using (RenderPass pass = Gfx.RenderPasses.New(cmds, "Scene")
			.Depth(depth, 1)
			.Color(target, .(100, 100, 100))
			.Color(normal, .ZERO)
			.Begin())
		{
			pass.SetViewport(target.Size, true, true);
			
			// Bind
			pass.Bind(pipeline);
			pass.Bind(0, .Uniform(ubo));

			MeshBuilder mb = scope .();

			// Ground
			float groundSize = 50;

			mb.Quad<Vertex>(
				.(.(-groundSize, 0, -groundSize), .(0, 1, 0), .WHITE),
				.(.(-groundSize, 0,  groundSize), .(0, 1, 0), .WHITE),
				.(.( groundSize, 0,  groundSize), .(0, 1, 0), .WHITE),
				.(.( groundSize, 0, -groundSize), .(0, 1, 0), .WHITE)
			);

			// Cubes
			RenderCube(mb, .(-10, 0, 10), .(10, 5, 10), .WHITE);
			RenderCube(mb, .(10, 0, 10), .(10, 5, 10), .(225, 25, 25));

			pass.Draw(mb.End());
		}
	}
	
	[Tracy.Profile]
	private void RenderUI() {
		if (!ImGuiCacti.NewFrame()) return;
		ImGui.Begin("Camera");

		ImGui.Text(scope $"X: {camera.pos.x}");
		ImGui.Text(scope $"Y: {camera.pos.y}");
		ImGui.Text(scope $"Z: {camera.pos.z}");
		ImGui.Text(scope $"Yaw: {camera.yaw}");
		ImGui.Text(scope $"Pitch: {camera.pitch}");

		ImGui.End();
	}
	
	[Tracy.Profile]
	private void RenderCube(MeshBuilder mb, Vec3f pos, Vec3f size, Color color) {
		// Bottom
		Color col = color.MulWithoutA(0.4f);
		mb.Quad<Vertex>(
			.(.(pos.x, pos.y, pos.z), .(0, -1, 0), col),
			.(.(pos.x, pos.y, pos.z + size.z), .(0, -1, 0), col),
			.(.(pos.x + size.x, pos.y, pos.z + size.z), .(0, -1, 0), col),
			.(.(pos.x + size.x, pos.y, pos.z), .(0, -1, 0), col)
		);

		// Top
		mb.Quad<Vertex>(
			.(.(pos.x, pos.y + size.y, pos.z), .(0, 1, 0), color),
			.(.(pos.x, pos.y + size.y, pos.z + size.z), .(0, 1, 0), color),
			.(.(pos.x + size.x, pos.y + size.y, pos.z + size.z), .(0, 1, 0), color),
			.(.(pos.x + size.x, pos.y + size.y, pos.z), .(0, 1, 0), color)
		);

		// Left
		col = color.MulWithoutA(0.6f);
		mb.Quad<Vertex>(
			.(.(pos.x, pos.y, pos.z), .(-1, 0, 0), col),
			.(.(pos.x, pos.y + size.y, pos.z), .(-1, 0, 0),  col),
			.(.(pos.x, pos.y + size.y, pos.z + size.z), .(-1, 0, 0),  col),
			.(.(pos.x, pos.y, pos.z + size.z), .(-1, 0, 0),  col)
		);

		// Right
		mb.Quad<Vertex>(
			.(.(pos.x + size.x, pos.y, pos.z), .(1, 0, 0),  col),
			.(.(pos.x + size.x, pos.y + size.y, pos.z), .(1, 0, 0),  col),
			.(.(pos.x + size.x, pos.y + size.y, pos.z + size.z), .(1, 0, 0),  col),
			.(.(pos.x + size.x, pos.y, pos.z + size.z), .(1, 0, 0),  col)
		);

		// Back
		col = color.MulWithoutA(0.8f);
		mb.Quad<Vertex>(
			.(.(pos.x, pos.y, pos.z), .(0, 0, -1),  col),
			.(.(pos.x, pos.y + size.y, pos.z), .(0, 0, -1), col),
			.(.(pos.x + size.x, pos.y + size.y, pos.z), .(0, 0, -1), col),
			.(.(pos.x + size.x, pos.y, pos.z), .(0, 0, -1), col)
		);

		// Forward
		mb.Quad<Vertex>(
			.(.(pos.x, pos.y, pos.z + size.z), .(0, 0, 1), col),
			.(.(pos.x, pos.y + size.y, pos.z + size.z), .(0, 0, 1), col),
			.(.(pos.x + size.x, pos.y + size.y, pos.z + size.z), .(0, 0, 1), col),
			.(.(pos.x + size.x, pos.y, pos.z + size.z), .(0, 0, 1), col)
		);
	}

	public static void Main(String[] args) {
		//RenderDoc.Init();

		scope CactiTest().Run();
	}
}