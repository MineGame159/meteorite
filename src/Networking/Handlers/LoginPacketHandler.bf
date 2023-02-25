using System;
using System.Diagnostics;

using Cacti;
using Cacti.Http;
using Cacti.Json;
using Cacti.Crypto;

namespace Meteorite;

public class LoginPacketHandler : PacketHandler {
	private ClientConnection connection;

	public this(ClientConnection connection) {
		this.connection = connection;
	}

	public override void OnConnectionLost() {
		LoginDisconnectS2CPacket packet = scope .();
		packet.reason = .Of("Connection lost");

		OnLoginDisconnect(packet);
	}

	// Handlers

	private void OnLoginDisconnect(LoginDisconnectS2CPacket packet) {
		me.Disconnect(packet.reason);
	}

	private void OnEncryptionRequest(EncryptionRequestS2CPacket packet) {
		// Create RNG
		RNG rng = scope .();

		// Create RSA
		RSA rsa = scope .();
		rsa.LoadPublicKey(packet.publicKey);

		// Get encrypted size
		int encryptedSize = rsa.GetEncryptedSize();
		Debug.Assert(encryptedSize == 128);

		// Generate shared secret
		uint8[16] sharedSecret = ?;
		rng.GenerateBlock(sharedSecret);

		// Encrypt shared secret
		uint8[] sharedSecretEncrypted = scope .[encryptedSize];
		rsa.Encrypt(rng, sharedSecret, sharedSecretEncrypted);

		// Encrypt verify token
		uint8[] verifyTokenEncrypted = scope .[encryptedSize];
		rsa.Encrypt(rng, packet.verifyToken, verifyTokenEncrypted);

		// Send join server HTTP request
		SHA1 sha = scope .();

		sha.Update(.((uint8*) packet.serverId.Ptr, packet.serverId.Length));
		sha.Update(sharedSecret);
		sha.Update(packet.publicKey);

		MicrosoftAccount account = (.) Meteorite.INSTANCE.accounts.active;

		String jsonString = scope .();
		JsonWriter json = scope .(scope StringWriter(jsonString), false);

		using (json.Object()) {
			json.String("accessToken", account.authData.mcAccessToken);
			json.String("selectedProfile", account.uuid);
			json.String("serverId", GetHexHash(sha, .. scope .()));
		}

		HttpResponse response = MsAuth.CLIENT.Send(scope HttpRequest(.Post)
			..SetUrl("https://sessionserver.mojang.com/session/minecraft/join")
			..SetBodyJson(jsonString)
		);

		Debug.Assert(response.Status == .NoContent);
		delete response;
		
		// Send encryption response and enable connection encryption
		connection.Send(scope EncryptionResponseC2SPacket(sharedSecretEncrypted, verifyTokenEncrypted));
		connection.EnableCompression(sharedSecret);
	}

	private static void GetHexHash(SHA1 sha, String str) {
		uint8[20] hash = sha.Final();

		if ((hash[0] & 0x80) == 0x80) {
			TwosComplement(ref hash);
			str.Append('-');
		}

		Utils.HexEncode(hash, str);
	}

	private static void TwosComplement(ref uint8[20] bytes) {
		bool carry = true;

		for (int i = bytes.Count - 1; i >= 0; i--) {
			bytes[i] = ~bytes[i] & 0xFF;

			if (carry) {
				carry = bytes[i] == 0xFF;
				bytes[i]++;
			}
		}
	}

	private void OnLoginSuccess(LoginSuccessS2CPacket packet) {
		connection.SetHandler(new PlayPacketHandler(connection));
	}

	// Base

	public override S2CPacket GetPacket(int32 id) => Impl.GetPacket(id);

	public override void Handle(S2CPacket packet) {
		if (packet.synchronised) me.Execute(new () => Impl.Dispatch(this, packet));
		else Impl.Dispatch(this, packet);
	}

	[PacketHandlerImpl]
	static class Impl {}
}