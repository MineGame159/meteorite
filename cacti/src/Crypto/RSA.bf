using System;
using System.Interop;

namespace Cacti.Crypto;

class RSA {
	private uint8[6288] handle;

	public this() {
		WolfSSL.VoidResult!(RsaKeyInit(&handle, null));
	}

	public ~this() {
		WolfSSL.VoidResult!(RsaKeyFree(&handle));
	}

	public Result<void> LoadPublicKey(Span<uint8> key) {
		uint32 offset = 0;
		return WolfSSL.VoidResult!(RsaPublicKeyDecode(key.Ptr, &offset, &handle, (.) key.Length));
	}

	public Result<int> GetEncryptedSize() {
		return WolfSSL.IntResult!(RsaEncryptSize(&handle));
	}

	public Result<void> Encrypt(RNG rng, Span<uint8> input, Span<uint8> output) {
		return WolfSSL.VoidResult!(RsaPublicEncrypt(input.Ptr, (.) input.Length, output.Ptr, (.) output.Length, &handle, &rng.[Friend]handle));
	}

	[LinkName("wc_InitRsaKey")]
	private static extern c_int RsaKeyInit(void* key, void* heap);

	[LinkName("wc_RsaPublicKeyDecode")]
	private static extern c_int RsaPublicKeyDecode(uint8* input, c_uint* offset, void* key, c_uint size);

	[LinkName("wc_RsaEncryptSize")]
	private static extern c_int RsaEncryptSize(void* key);

	[LinkName("wc_RsaPublicEncrypt")]
	private static extern c_int RsaPublicEncrypt(uint8* input, c_uint inputSize, uint8* output, c_uint outputSize, void* key, void* rng);

	[LinkName("wc_FreeRsaKey")]
	private static extern c_int RsaKeyFree(void* key);
}