using System;
using System.Interop;

namespace Cacti.Crypto;

class AES {
	enum Direction {
		Encrypt,
		Decrypt
	}

	private uint8[848] handle;

	public this() {
		WolfSSL.VoidResult!(AesInit(&handle, null, -2));
	}

	public ~this() {
		AesFree(&handle);
	}

	public Result<void> SetKey(Span<uint8> key, Span<uint8> iv, Direction dir) {
		return WolfSSL.VoidResult!(AesSetKey(&handle, key.Ptr, (.) key.Length, iv.Ptr, (.) dir));
	}

	public Result<void> EncryptCfb8(Span<uint8> input, uint8* output) {
		return WolfSSL.VoidResult!(AesCfb8Encrypt(&handle, output, input.Ptr, (.) input.Length));
	}

	public Result<void> DecryptCfb8(Span<uint8> input, uint8* output) {
		return WolfSSL.VoidResult!(AesCfb8Decrypt(&handle, output, input.Ptr, (.) input.Length));
	}

	[LinkName("wc_AesInit")]
	private static extern c_int AesInit(void* aes, void* heap, c_int deviceId);

	[LinkName("wc_AesSetKey")]
	private static extern c_int AesSetKey(void* aes, uint8* key, c_uint size, uint8* iv, c_int dir);

	[LinkName("wc_AesCfb8Encrypt")]
	private static extern c_int AesCfb8Encrypt(void* aes, uint8* output, uint8* input, c_uint inputSize);

	[LinkName("wc_AesCfb8Decrypt")]
	private static extern c_int AesCfb8Decrypt(void* aes, uint8* output, uint8* input, c_uint inputSize);

	[LinkName("wc_AesFree")]
	public static extern void AesFree(void* aes);
}