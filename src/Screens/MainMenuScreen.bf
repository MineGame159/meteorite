using System;

using Cacti;
using Cacti.Http;
using Cacti.Json;

using ImGui;

namespace Meteorite;

class MainMenuScreen : Screen {
	private String address = new .("localhost") ~ delete _;

	private String crackedUsername = new .() ~ delete _;
	private bool addingCracked;

	private bool join;

	public this() : base("Main Menu") {}

	public override void Render() {
		bool wasAddingCracked = addingCracked;
		if (wasAddingCracked) ImGui.BeginDisabled();

		base.Render();

		ImGui.SetNextWindowSizeConstraints(.(300, 0), .(float.MaxValue, float.MaxValue));
		ImGui.Begin("Accounts", null, .AlwaysAutoResize);
		RenderAccounts();
		ImGui.End();

		if (wasAddingCracked) {
			ImGui.EndDisabled();
			
			ImGui.Begin("Add Cracked account", null, .AlwaysAutoResize);
			RenderAddCracked();
			ImGui.End();
		}

		if (join) {
			join = false;

			String ip = scope .();
			int32 port = 0;

			switch (GetIPWithPort(ip, ref port)) {
			case .Ok:	Meteorite.INSTANCE.Join(ip, port, address);
			case .Err:	Log.Error("Failed to resolved address '{}'", address);
			}
		}
	}

	private Result<void> GetIPWithPort(String ip, ref int32 port) {
		StringView address = address..Trim();

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

	private bool IsIPv4(StringView address) {
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

	private void RenderAccounts() {
		AccountManager accounts = Meteorite.INSTANCE.accounts;

		// Accounts
		int32 i = 0;

		for (Account account in accounts) {
			ImGui.PushID(i++);
			bool active = account == accounts.active;

			if (active) ImGui.PushStyleColor(.Text, *ImGui.GetStyleColorVec4(.SliderGrabActive));
			ImGui.Text("({}) {}", account.type == .Cracked ? "CR" : "MS", account.username);
			if (active) ImGui.PopStyleColor();

			ImGui.Style* style = ImGui.GetStyle();
			float selectWidth = ImGui.CalcTextSize("Select").x + style.FramePadding.x * 2;
			float deleteWidth = ImGui.CalcTextSize("X").x + style.FramePadding.x * 2;

			ImGui.BeginDisabled(active);
			ImGui.SameLine(ImGui.GetWindowContentRegionMax().x - (selectWidth + style.CellPadding.x * 2 + deleteWidth));
			if (ImGui.Button("Select")) {
				accounts.Select(account);
			}
			ImGui.EndDisabled();

			ImGui.SameLine();
			if (ImGui.Button("X")) {
				accounts.Delete(account);
			}

			ImGui.PopID();
		}

		if (!accounts.IsEmpty) {
			ImGui.Separator();
		}

		// Add new account
		float spacing = ImGui.GetStyle().ItemSpacing.x;
		float width = ImGui.GetWindowContentRegionMax().x / 2 - spacing;

		if (ImGui.Button("Add Cracked", .(width, 0))) {
			addingCracked = true;
		}

		ImGui.SameLine();
		if (ImGui.Button("Add Microsoft", .(width, 0))) {
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

	private void RenderAddCracked() {
		using (ImGuiOptions opts = .(200)) {
			opts.InputText("Username", crackedUsername, 16);
		}

		ImGuiCacti.Separator();

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
}