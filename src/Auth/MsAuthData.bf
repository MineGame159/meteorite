using System;

using Cacti;

namespace Meteorite;

class MsAuthData {
	public append String msaAccessToken = .();
	public append String msaRefreshToken = .();
	public DateTime msaValidUntil;

	public append String xblToken = .();
	public append String xblUserHash = .();
	public DateTime xblValidUntil;

	public append String xstsToken = .();
	public DateTime xstsValidUntil;

	public append String mcAccessToken = .();
	public DateTime mcValidUntil;

	public bool ownsMc;

	public Json ToJson() {
		Json json = .Object();

		json["msa_access_token"] = .String(msaAccessToken);
		json["msa_refresh_token"] = .String(msaRefreshToken);
		json["msa_valid_until"] = .String(msaValidUntil.Ticks.ToString(.. scope .()));

		json["xbl_token"] = .String(xblToken);
		json["xbl_user_hash"] = .String(xblUserHash);
		json["xbl_valid_until"] = .String(xblValidUntil.Ticks.ToString(.. scope .()));

		json["xsts_token"] = .String(xstsToken);
		json["xsts_valid_until"] = .String(xstsValidUntil.Ticks.ToString(.. scope .()));

		json["mc_access_token"] = .String(mcAccessToken);
		json["mc_valid_until"] = .String(mcValidUntil.Ticks.ToString(.. scope .()));

		return json;
	}

	public void FromJson(Json json) {
		msaAccessToken.Set(json["msa_access_token"].AsString);
		msaRefreshToken.Set(json["msa_refresh_token"].AsString);
		msaValidUntil = .(int64.Parse(json["msa_valid_until"].AsString));

		xblToken.Set(json["xbl_token"].AsString);
		xblUserHash.Set(json["xbl_user_hash"].AsString);
		xblValidUntil = .(int64.Parse(json["xbl_valid_until"].AsString));

		xstsToken.Set(json["xsts_token"].AsString);
		xstsValidUntil = .(int64.Parse(json["xsts_valid_until"].AsString));

		mcAccessToken.Set(json["mc_access_token"].AsString);
		mcValidUntil = .(int64.Parse(json["mc_valid_until"].AsString));
	}
}