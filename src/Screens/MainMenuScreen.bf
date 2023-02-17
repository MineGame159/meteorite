using System;

using Cacti;
using Cacti.Http;
using Cacti.Json;
using Cacti.Graphics;

using ImGui;

namespace Meteorite;

class MainMenuScreen : Screen {
	private String address = new .("localhost") ~ delete _;

	private Server serverToAdd;
	private bool addingServer;

	private String crackedUsername = new .() ~ delete _;
	private bool addingCracked;

	private bool join;

	public this() : base("Main Menu") {}

	public override void Render() {
		bool wasAddingServer = addingServer;
		bool wasAddingCracked = addingCracked;

		ImGui.BeginDisabled(wasAddingServer || wasAddingCracked);

		base.Render();

		ImGui.SetNextWindowSizeConstraints(.(300, 0), .(float.MaxValue, float.MaxValue));
		ImGui.Begin("Servers", null, .AlwaysAutoResize);
		RenderServers();
		ImGui.End();

		ImGui.SetNextWindowSizeConstraints(.(300, 0), .(float.MaxValue, float.MaxValue));
		ImGui.Begin("Accounts", null, .AlwaysAutoResize);
		RenderAccounts();
		ImGui.End();

		ImGui.EndDisabled();

		if (wasAddingServer) {
			ImGui.Begin("Add server", null, .AlwaysAutoResize);
			RenderAddServer();
			ImGui.End();
		}

		if (wasAddingCracked) {
			ImGui.Begin("Add Cracked account", null, .AlwaysAutoResize);
			RenderAddCracked();
			ImGui.End();
		}

		if (join) {
			join = false;
			Join();
		}
	}

	protected override void RenderImpl() {
		using (ImGuiOptions opts = .(200)) {
			opts.InputText("Address", address, 32);
			opts.SliderInt("Render Distance", ref Meteorite.INSTANCE.options.renderDistance, 2, 32);
		}

		bool disabled = Meteorite.INSTANCE.accounts.active == null;
		ImGui.BeginDisabled(disabled);

		if (ImGui.Button("Connect", .(-1, 0)) && !disabled) {
			join = true;
		}

		ImGui.EndDisabled();
	}

	private void RenderServers() {
		ServerManager servers = Meteorite.INSTANCE.servers;

		float spacing = ImGui.GetStyle().ItemSpacing.x;
		float framePadding = ImGui.GetStyle().FramePadding.x;
		float arrowButtonWidth = ImGui.GetFrameHeight() + framePadding;

		float joinWidth = ImGui.CalcTextSize("Join").x + framePadding * 2;
		float removeWidth = ImGui.CalcTextSize("X").x + framePadding * 2;

		Server moveUp = null;
		Server moveDown = null;
		Server remove = null;

		for (Server server in servers) {
			ImGui.PushID((.) @server.Index);

			ImGui.AlignTextToFramePadding();
			ImGui.Text(server.name);

			if (ImGui.IsItemHovered(.DelayNormal)) {
				ImGui.SetTooltip(server.address);
			}

			float joinX = ImGui.GetContentRegionMax().x - arrowButtonWidth * 2 - spacing * 2 - joinWidth - removeWidth;

			ImGui.SameLine(joinX);
			if (ImGui.Button("Join")) {
				address.Set(server.address);
				join = true;
			}

			ImGui.SameLine();
			if (ImGui.ArrowButton("up", .Up)) {
				moveUp = server;
			}

			ImGui.SameLine();
			if (ImGui.ArrowButton("down", .Down)) {
				moveDown = server;
			}

			ImGui.SameLine();
			if (ImGui.Button("X")) {
				remove = server;
			}

			ImGui.PopID();
		}

		if (moveUp != null) servers.MoveUp(moveUp);
		else if (moveDown != null) servers.MoveDown(moveDown);
		else if (remove != null) servers.Remove(remove);

		if (!servers.IsEmpty) {
			ImGui.Separator();
		}

		using (ImGuiButtons btns = .(1)) {
			if (btns.Button("Add")) {
				serverToAdd = new .();
				addingServer = true;
			}
		}
	}

	private void RenderAddServer() {
		using (ImGuiOptions opts = .(200)) {
			opts.InputText("Name", serverToAdd.name, 64);
			opts.InputText("Address", serverToAdd.address, 64);
		}

		ImGui.Separator();

		using (ImGuiButtons btns = .(2)) {
			if (btns.Button("Cancel")) {
				delete serverToAdd;
				addingServer = false;
			}

			if (btns.Button("Add")) {
				Meteorite.INSTANCE.servers.Add(serverToAdd);

				serverToAdd = null;
				addingServer = false;
			}
		}
	}

	private void RenderAccounts() {
		AccountManager accounts = Meteorite.INSTANCE.accounts;

		// Accounts
		Account remove = null;

		for (Account account in accounts) {
			ImGui.PushID((.) @account.Index);
			bool active = account == accounts.active;

			if (active) ImGui.PushStyleColor(.Text, *ImGui.GetStyleColorVec4(.SliderGrabActive));
			ImGui.AlignTextToFramePadding();
			ImGui.Text("({}) {}", account.type == .Cracked ? "CR" : "MS", account.username);
			if (active) ImGui.PopStyleColor();

			ImGui.Style* style = ImGui.GetStyle();
			float selectWidth = ImGui.CalcTextSize("Select").x + style.FramePadding.x * 2;
			float removeWidth = ImGui.CalcTextSize("X").x + style.FramePadding.x * 2;

			ImGui.BeginDisabled(active);
			ImGui.SameLine(ImGui.GetWindowContentRegionMax().x - (selectWidth + style.CellPadding.x * 2 + removeWidth));
			if (ImGui.Button("Select")) {
				accounts.Select(account);
			}
			ImGui.EndDisabled();

			ImGui.SameLine();
			if (ImGui.Button("X")) {
				remove = account;
			}

			ImGui.PopID();
		}

		if (!accounts.IsEmpty) {
			ImGui.Separator();
		}

		if (remove != null) accounts.Remove(remove);

		// Add new account
		using (ImGuiButtons btns = .(2)) {
			if (btns.Button("Add Cracked")) {
				addingCracked = true;
			}

			if (btns.Button("Add Microsoft")) {
				MicrosoftAccount account = new .();

				if (account.Authenticate() == .Err) {
					Log.Error("Failed to add a new Microsoft account");
					delete account;
				}
				else {
					accounts.Add(account);
				}
			}
		}
	}

	private void RenderAddCracked() {
		using (ImGuiOptions opts = .(200)) {
			opts.InputText("Username", crackedUsername, 16);
		}

		ImGui.Separator();

		using (ImGuiButtons btns = .(2)) {
			if (btns.Button("Cancel")) {
				addingCracked = false;
			}

			if (btns.Button("Add")) {
				Meteorite.INSTANCE.accounts.Add(new CrackedAccount(crackedUsername));

				crackedUsername.Clear();
				addingCracked = false;
			}
		}
	}

	// Auth

	private void Join() {
		String ip = scope .();
		int32 port = 0;

		switch (GetIPWithPort(address, ip, ref port)) {
		case .Ok:	Meteorite.INSTANCE.Join(ip, port, address);
		case .Err:	Log.Error("Failed to resolved address '{}'", address);
		}
	}

	private static Result<void> GetIPWithPort(StringView address, String ip, ref int32 port) {
		var address;

		address = address..Trim();

		defer {
			// Use 25565 as a default port if one wasn't assigned
			if (port == 0) {
				port = 25565;
			}
		}

		// Parse port
		int portI = address.IndexOf(':');

		if (portI != -1) {
			StringView portStr = address[(portI + 1)...];
			address = address[...(portI - 1)];

			switch (int32.Parse(portStr)) {
			case .Ok(let val):	port = val;
			case .Err:			return .Err;
			}

			if (port > uint16.MaxValue) {
				return .Err;
			}
		}

		// Check if the address equals localhost
		if (address == "localhost") {
			ip.Set("127.0.0.1");
			return .Ok;
		}

		// Check if the address is in the format of a raw IPv4 address
		if (IsIPv4(address)) {
			ip.Set(address);
			return .Ok;
		}

		// Make a HTTP request to mcsrvstat.us to resolve the hostname
		HttpResponse response = MsAuth.CLIENT.Send(scope HttpRequest(.Get)
			..SetUrl(scope $"https://api.mcsrvstat.us/2/{address}")
			..SetHeader(.Accept, "application/json")
		);
		defer delete response;

		if (response.Status != .OK) {
			return .Err;
		}

		Json json = response.GetJson().GetOrPropagate!();

		if (json.GetBool("online")) {
			ip.Set(json["ip"].AsString);

			if (port == 0) {
				port = (.) json["port"].AsNumber;
			}

			json.Dispose(); // defer does not seems to be working
			return .Ok;
		}

		json.Dispose();
		return .Err;
	}

	private static bool IsIPv4(StringView address) {
		if (address.Count('.') != 3) return false;

		for (let part in address.Split('.')) {
			switch (uint32.Parse(part)) {
			case .Ok(let val):
				if (val > 255) return false;
			case .Err:
				return false;
			}
		}

		return true;
	}
}