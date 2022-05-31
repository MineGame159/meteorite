using System;

using ImGui;

namespace Meteorite {
	static class MainMenu {
		private static char8[16] username = "Meteorite";
		private static char8[32] ip = "localhost";
		private static char8[6] port = "25565";
		private static int32 viewDistance = 6;

		public static void Render() {
			ImGui.Begin("Menu", null, .AlwaysAutoResize);

			ImGui.InputText("Username", &username, username.Count);
			ImGui.InputText("IP", &ip, ip.Count);
			ImGui.InputText("Port", &port, port.Count);
			ImGui.DragInt("View Distance", &viewDistance, 1, 2, 32);

			if (ImGui.Button("Connect", .(-1, 0))) {
				Meteorite.INSTANCE.Join(.(&ip), int32.Parse(.(&port)), viewDistance);
			}

			ImGui.End();
		}
	}
}