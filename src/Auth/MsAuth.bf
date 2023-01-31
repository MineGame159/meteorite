using System;
using System.Threading;
using System.Collections;
using System.Diagnostics;

using Cacti;
using Cacti.Http;

namespace Meteorite;

static class MsAuth {
	private const String CLIENT_ID = "4673b348-3efa-4f6a-bbb6-34e141cdc638";
	private const uint16 SERVER_PORT = 9675;

	public static HttpClient CLIENT = new .() ~ delete _;

	private static HttpServer SERVER;
	private static WaitEvent SERVER_STOP_EVENT;
	private static String LOGIN_CODE;

	public static Result<void> Auth(MsAuthData data) {
		if (data.msaAccessToken.IsEmpty) {
			AskToLogin(data).GetOrPropagate!();
		}

		RefreshMSA(data).GetOrPropagate!();
		AuthXBL(data).GetOrPropagate!();
		AuthXSTS(data).GetOrPropagate!();
		AuthMC(data).GetOrPropagate!();
		CheckOwnership(data).GetOrPropagate!();

		return .Ok;
	}

	private static Result<void> RefreshMSA(MsAuthData data) {
		if (DateTime.Now < data.msaValidUntil) return .Ok;

		Dictionary<StringView, StringView> body = scope .();
		body["client_id"] = CLIENT_ID;
		body["grant_type"] = "refresh_token";
		body["refresh_token"] = data.msaRefreshToken;
		body["redirect_uri"] = scope $"http://127.0.0.1:{SERVER_PORT}";

		HttpResponse response = CLIENT.Send(scope HttpRequest(.Post)
			..SetUrl(scope $"https://login.live.com/oauth20_token.srf")
			..SetBody(body)
		);
		
		defer delete response;
		if (response.Status != .OK) return .Err;

		Json json = response.GetJson();
		
		data.msaAccessToken.Set(json["access_token"].AsString);
		data.msaRefreshToken.Set(json["refresh_token"].AsString);
		data.msaValidUntil = DateTime.Now + TimeSpan.FromSeconds(json["expires_in"].AsNumber);

		json.Dispose();
		return .Ok;
	}

	private static Result<void> AuthXBL(MsAuthData data) {
		if (DateTime.Now < data.xblValidUntil) return .Ok;

		HttpResponse response = CLIENT.Send(scope HttpRequest(.Post)
			..SetUrl("https://user.auth.xboxlive.com/user/authenticate")
			..SetBodyJson(scope $"\{\"Properties\":\{\"AuthMethod\":\"RPS\",\"SiteName\":\"user.auth.xboxlive.com\",\"RpsTicket\":\"d={data.msaAccessToken}\"\},\"RelyingParty\":\"http://auth.xboxlive.com\",\"TokenType\":\"JWT\"\}")
		);

		defer delete response;
		if (response.Status != .OK) return .Err;

		Json json = response.GetJson();

		data.xblToken.Set(json["Token"].AsString);
		data.xblUserHash.Set(json["DisplayClaims"]["xui"].AsArray[0]["uhs"].AsString);
		data.xblValidUntil = ParseTime(json["NotAfter"].AsString);

		json.Dispose();
		return .Ok;
	}

	private static Result<void> AuthXSTS(MsAuthData data) {
		if (DateTime.Now < data.xstsValidUntil) return .Ok;

		HttpResponse response = CLIENT.Send(scope HttpRequest(.Post)
			..SetUrl("https://xsts.auth.xboxlive.com/xsts/authorize")
			..SetBodyJson(scope $"\{\"Properties\":\{\"SandboxId\":\"RETAIL\",\"UserTokens\":[\"{data.xblToken}\"]\},\"RelyingParty\":\"rp://api.minecraftservices.com/\",\"TokenType\":\"JWT\"\}")
		);

		defer delete response;
		if (response.Status != .OK) return .Err;

		Json json = response.GetJson();

		data.xstsToken.Set(json["Token"].AsString);
		data.xstsValidUntil = ParseTime(json["NotAfter"].AsString);

		json.Dispose();
		return .Ok;
	}

	private static Result<void> AuthMC(MsAuthData data) {
		if (DateTime.Now < data.mcValidUntil) return .Ok;

		HttpResponse response = CLIENT.Send(scope HttpRequest(.Post)
			..SetUrl("https://api.minecraftservices.com/authentication/login_with_xbox")
			..SetBodyJson(scope $"\{\"identityToken\":\"XBL3.0 x={data.xblUserHash};{data.xstsToken}\"\}")
		);

		defer delete response;
		if (response.Status != .OK) return .Err;

		Json json = response.GetJson();

		data.mcAccessToken.Set(json["access_token"].AsString);
		data.mcValidUntil = DateTime.Now + TimeSpan.FromSeconds(json["expires_in"].AsNumber);

		json.Dispose();
		return .Ok;
	}

	private static Result<void> CheckOwnership(MsAuthData data) {
		HttpResponse response = CLIENT.Send(scope HttpRequest(.Get)
			..SetUrl("https://api.minecraftservices.com/entitlements/mcstore")
			..SetHeader(.Authorization, scope $"Bearer {data.mcAccessToken}")
		);

		defer delete response;
		if (response.Status != .OK) return .Err;

		Json json = response.GetJson();

		data.ownsMc = !json["items"].AsArray.IsEmpty;

		json.Dispose();
		return .Ok;
	}

	private static Result<void> AskToLogin(MsAuthData data) {
		// Start a local server, wait for a request and delete the server
		SERVER = new .(SERVER_PORT, new => ServerHandler);
		SERVER_STOP_EVENT = scope .();

		SERVER.Start().GetOrPropagate!();
		Utils.OpenUrl(scope $"https://login.live.com/oauth20_authorize.srf?client_id={CLIENT_ID}&response_type=code&redirect_uri=http://127.0.0.1:{SERVER_PORT}&scope=XboxLive.signin%20offline_access&prompt=select_account");

		SERVER_STOP_EVENT.WaitFor(10000);

		SERVER.Release();
		SERVER = null;
		SERVER_STOP_EVENT = null;

		// Auth MSA
		if (LOGIN_CODE == null) return .Err;

		AuthMSA(data, LOGIN_CODE);
		DeleteAndNullify!(LOGIN_CODE);

		return .Ok;
	}

	private static Result<void> AuthMSA(MsAuthData data, StringView loginCode) {
		Dictionary<StringView, StringView> body = scope .();
		body["client_id"] = CLIENT_ID;
		body["grant_type"] = "authorization_code";
		body["code"] = loginCode;
		body["redirect_uri"] = scope $"http://127.0.0.1:{SERVER_PORT}";

		HttpResponse response = CLIENT.Send(scope HttpRequest(.Post)
			..SetUrl("https://login.live.com/oauth20_token.srf")
			..SetBody(body)
		);

		defer delete response;
		if (response.Status != .OK) return .Err;

		Json json = response.GetJson();

		data.msaAccessToken.Set(json["access_token"].AsString);
		data.msaRefreshToken.Set(json["refresh_token"].AsString);
		data.msaValidUntil = DateTime.Now + TimeSpan.FromSeconds(json["expires_in"].AsNumber);

		json.Dispose();
		return .Ok;
	}

	private static HttpResponse ServerHandler(HttpRequest request) {
		defer SERVER_STOP_EVENT.Set();

		mixin Error() {
			return new HttpResponse(.BadRequest)..SetBody("Failed to get code parameter");
		}

		int startI = request.Url.path.IndexOf("?code=");
		if (startI == -1) Error!();

		StringView code = request.Url.path[(startI + 6)...];
		LOGIN_CODE = new .(code);

		return new HttpResponse(.OK)..SetBody("You may close this page now");
	}

	private static DateTime ParseTime(StringView string) {
		StringSplitEnumerator tSplit = string.Split('T');
		StringSplitEnumerator dashSplit = tSplit.GetNext().Value.Split('-');
		StringSplitEnumerator colonSplit = tSplit.GetNext().Value..RemoveFromEnd(1).Split(':');

		int year = int.Parse(dashSplit.GetNext());
		int month = int.Parse(dashSplit.GetNext());
		int day = int.Parse(dashSplit.GetNext());

		int hour = int.Parse(colonSplit.GetNext());
		int minute = int.Parse(colonSplit.GetNext());
		int second = (.) double.Parse(colonSplit.GetNext());

		return .(year, month, day, hour, minute, second);
	}
}