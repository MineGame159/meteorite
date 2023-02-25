using System;

using Cacti;
using Cacti.Http;
using Cacti.Json;

namespace Meteorite;

enum AccountType {
	case Cracked,
		 Microsoft;

	public Account Load(Json json) {
		Account account;

		if (this == .Cracked) account = new CrackedAccount("");
		else account = new MicrosoftAccount();

		account.FromJson(json);

		return account;
	}
}

abstract class Account {
	public AccountType type;

	public append String username = .();
	public UUID uuid;

	public this(AccountType type) {
		this.type = type;
	}

	public abstract Result<void> Authenticate();

	public virtual void ToJson(bool active, JsonWriter json) {
		using (json.Object()) {
			ToJsonBase(active, json);
		}
	}

	protected void ToJsonBase(bool active, JsonWriter json) {
		json.Bool("active", active);

		json.String("type", type);
		json.String("username", username);
		json.String("uuid", uuid);
	}

	public virtual void FromJson(Json json) {
		username.Set(json["username"].AsString);
		uuid = .Parse(json["uuid"].AsString, true);
	}
}

class CrackedAccount : Account {
	public this(StringView username) : base(.Cracked) {
		this.username.Set(username);
	}

	public override Result<void> Authenticate() {
		return .Ok;
	}
}

class MicrosoftAccount : Account {
	public append MsAuthData authData = .();

	public this() : base(.Microsoft) {}

	public override Result<void> Authenticate() {
		// Authenticate
		MsAuth.Auth(authData).GetOrPropagate!();
		if (!authData.ownsMc) return .Err;

		// Fetch username and uuid
		HttpResponse response = MsAuth.CLIENT.Send(scope HttpRequest(.Get)
			..SetUrl("https://api.minecraftservices.com/minecraft/profile")
			..SetHeader(.Authorization, scope $"Bearer {authData.mcAccessToken}")
		);

		defer delete response;
		if (response.Status != .OK) return .Err;

		JsonTree tree = response.GetJson();
		Json json = tree.root;

		username.Set(json["name"].AsString);
		uuid = .Parse(json["id"].AsString, true);

		delete tree;
		return .Ok;
	}

	public override void ToJson(bool active, JsonWriter json) {
		using (json.Object()) {
			ToJsonBase(active, json);

			json.SetNextValueName("auth");
			authData.ToJson(json);
		}
	}

	public override void FromJson(Json json) {
		base.FromJson(json);

		authData.FromJson(json["auth"]);
	}
}