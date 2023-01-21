using System;

using ImGui;

namespace Meteorite;

class MainMenuScreen : Screen {
	private char8[16] username = "Meteorite";
	private char8[32] ip = "localhost";
	private char8[6] port = "25565";

	public this() : base("Main Menu") {}

	protected override void RenderImpl() {
		ImGui.InputText("Username", &username, username.Count);
		ImGui.InputText("IP", &ip, ip.Count);
		ImGui.InputText("Port", &port, port.Count);
		ImGui.SliderInt("Render Distance", &Meteorite.INSTANCE.options.renderDistance, 2, 32);

		if (ImGui.Button("Connect", .(-1, 0))) {
			Meteorite.INSTANCE.Join(.(&ip), int32.Parse(.(&port)), .(&username));
		}
	}
}