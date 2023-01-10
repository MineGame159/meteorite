using System;
using System.Collections;

using Cacti;
using ImGui;

namespace Meteorite;

class CactiTest : Application {
	private const String VERTEX_SHADER = """
		#version 460

		layout (location = 0) in vec2 pos;

		layout (set = 0, binding = 0) uniform Uniforms {
			mat4 projection;
		};

		void main() {
			gl_Position = projection * vec4(pos, 0.0, 1.0);
		}
		""";

	private const String FRAGMENT_SHADER = """
		#version 460

		layout (location = 0) out vec4 color;

		void main() {
			color = vec4(1.0, 0.0, 0.0, 1.0);
		}
		""";

	private Pipeline pipeline ~ delete _;

	private GpuBuffer ubo ~ delete _;
	private DescriptorSet set ~ delete _;

	public this() : base("Cacti Test") {
		DescriptorSetLayout setLayout = Gfx.DescriptorSetLayouts.Get(.UniformBuffer);

		pipeline = Gfx.Pipelines.New("Yoo")
			.VertexFormat(scope VertexFormat().Attribute(.Float, 2))
			.Primitive(.Traingles)
			.Shader(VERTEX_SHADER, FRAGMENT_SHADER, path: false)
			.Sets(setLayout)
			.Cull(.None, .CounterClockwise)
			.Create();

		ubo = Gfx.Buffers.Create(.Uniform, .Mappable, sizeof(Mat4), "UBO");
		set = Gfx.DescriptorSets.Create(setLayout, .Uniform(ubo));
	}

	protected override void Update(double delta) {

	}

	protected override void Render(List<CommandBuffer> commandBuffers, GpuImage target, double delta) {
		CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
		commandBuffers.Add(cmds);

		cmds.Begin();
		cmds.SetViewport(target.size, scissor: true);
		cmds.BeginPass(null, .(target, .(225, 225, 225)));

		Mat4 projection = .Ortho(0, target.size.x, 0, target.size.y);
		ubo.Upload(&projection, ubo.size);

		cmds.Bind(pipeline);
		cmds.Bind(set, 0);

		MeshBuilder mb = scope .();
		mb.Quad<Vec2f>(
			.(100, 100),
			.(100, 400),
			.(600, 400),
			.(600, 100)
		);
		cmds.Draw(mb.End());

		cmds.EndPass();
		cmds.End();

		// ImGui

		if (ImGuiCacti.NewFrame()) {
			ImGui.ShowDemoWindow();
		}
	}

	public static void Main() {
		scope CactiTest().Run();
	}
}