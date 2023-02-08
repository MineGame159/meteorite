using System;
using System.Collections;

using Cacti;
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

	private GpuImage depth ~ delete _;
	private GpuImage normal ~ delete _;

	private Pipeline pipeline;

	private GpuBuffer ubo ~ delete _;
	private DescriptorSet set ~ delete _;

	private Camera camera ~ delete _;

	public this() : base("Cacti Test") {
		depth = Gfx.Images.Create(.Depth, .DepthAttachment, window.size, "Depth");
		normal = Gfx.Images.Create(.RGBA32, .ColorAttachment, window.size, "Normal");

		DescriptorSetLayout setLayout = Gfx.DescriptorSetLayouts.Get(.UniformBuffer);

		pipeline = Gfx.Pipelines.Get(scope PipelineInfo("Yoo")
			.VertexFormat(Vertex.FORMAT)
			.Primitive(.Traingles)
			.Shader(VERTEX_SHADER, FRAGMENT_SHADER, path: false)
			.Sets(setLayout)
			.Cull(.None, .Clockwise)
			.Depth(true, true, true)
			.Targets(
				.(.BGRA, .Default()),
				.(.RGBA32, .Disabled())
			)
		);

		ubo = Gfx.Buffers.Create(.Uniform, .Mappable, sizeof(Uniforms), "UBO");
		set = Gfx.DescriptorSets.Create(setLayout, .Uniform(ubo));

		camera = new .(window);
		camera.pos = .(5, 8, -3);
		camera.yaw = -90;
	}

	protected override void Update(double delta) {
		if (Input.IsKeyReleased(.Escape)) window.MouseHidden = !window.MouseHidden;

		camera.FlightMovement((.) delta);
		camera.Update(1000);
	}

	protected override void Render(List<CommandBuffer> commandBuffers, GpuImage target, double delta) {
		UploadUniforms();

		CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
		commandBuffers.Add(cmds);

		cmds.Begin();
		cmds.SetViewport(target.size, true, true);

		RenderScene(cmds, target);

		cmds.End();

		RenderUI();
	}

	private void UploadUniforms() {
		Uniforms uniforms = .();

		uniforms.projection = camera.proj;
		uniforms.view = camera.view;

		ubo.Upload(&uniforms, ubo.size);
	}

	private void RenderScene(CommandBuffer cmds, GpuImage target) {
		using (RenderPass pass = Gfx.RenderPasses.Begin(cmds, "Main", .(depth, 1), .(target, .(100, 100, 100)), .(normal, .ZERO))) {
			// Bind
			cmds.Bind(pipeline);
			cmds.Bind(set, 0);
	
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
	
			cmds.Draw(mb.End());
		}
	}

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

	public static void Main() {
		//RenderDoc.Init();

		scope CactiTest().Run();
	}
}