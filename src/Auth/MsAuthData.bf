using System;

using Cacti;
using Cacti.Json;

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

	public void ToJson(JsonWriter json) {
		using (json.Object()) {
			json.String("msa_access_token", msaAccessToken);
			json.String("msa_refresh_token", msaRefreshToken);
			json.String("msa_valid_until", msaValidUntil.Ticks);

			json.String("xbl_token", xblToken);
			json.String("xbl_user_hash", xblUserHash);
			json.String("xbl_valid_until", xblValidUntil.Ticks);

			json.String("xsts_token", xstsToken);
			json.String("xsts_valid_until", xstsValidUntil.Ticks);

			json.String("mc_access_token", mcAccessToken);
			json.String("mc_valid_until", mcValidUntil.Ticks);
		}
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