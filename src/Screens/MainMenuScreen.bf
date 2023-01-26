using System;

using Cacti;
using ImGui;

namespace Meteorite;

class MainMenuScreen : Screen {
	private char8[32] ip = "localhost";
	private char8[6] port = "25565";

	private char8[16] crackedUsername;
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
			
			ImGui.SetNextWindowSizeConstraints(.(300, 0), .(float.MaxValue, float.MaxValue));
			ImGui.Begin("Add Cracked account");
			RenderAddCracked();
			ImGui.End();
		}

		if (join) {
			Meteorite.INSTANCE.Join(.(&ip), int32.Parse(.(&port)));
		}
	}

	protected override void RenderImpl() {
		ImGui.InputText("IP", &ip, ip.Count);
		ImGui.InputText("Port", &port, port.Count);
		ImGui.SliderInt("Render Distance", &Meteorite.INSTANCE.options.renderDistance, 2, 32);

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
		ImGui.SetNextItemWidth(ImGui.GetContentRegionMax().x - ImGui.GetStyle().CellPadding.x - ImGui.CalcTextSize(" Username").x);
		ImGui.InputText("Username", &crackedUsername, crackedUsername.Count, .CharsNoBlank);
		
		float spacing = ImGui.GetStyle().ItemSpacing.x;
		float width = ImGui.GetWindowContentRegionMax().x / 2 - spacing;

		if (ImGui.Button("Cancel", .(width, 0))) {
			addingCracked = false;
		}

		ImGui.SameLine();
		if (ImGui.Button("Add", .(width, 0))) {
			Meteorite.INSTANCE.accounts.Add(new CrackedAccount(.(&crackedUsername)));

			Internal.MemSet(&crackedUsername, 0, crackedUsername.Count);
			addingCracked = false;
		}
	}
}