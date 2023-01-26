using System;
using System.Interop;

namespace Cacti.Crypto;

class RNG {
	private uint8[32] handle;

	public this() {
		WolfSSL.VoidResult!(RngInit(&handle));
	}

	public ~this() {
		WolfSSL.VoidResult!(RngFree(&handle));
	}

	public Result<uint8> GenerateByte() {
		uint8 byte = 0;

		if (RngGenerateByte(&handle, &byte) < 0) {
			return .Err;
		}

		return byte;
	}

	public Result<void> GenerateBlock(Span<uint8> block) {
		return WolfSSL.VoidResult!(RngGenerateBlock(&handle, block.Ptr, (.) block.Length));
	}

	[LinkName("wc_InitRng")]
	private static extern c_int RngInit(void* rng);

	[LinkName("wc_RNG_GenerateByte")]
	private static extern c_int RngGenerateByte(void* rng, uint8* byte);

	[LinkName("wc_RNG_GenerateBlock")]
	private static extern c_int RngGenerateBlock(void* rng, uint8* block, c_uint size);

	[LinkName("wc_FreeRng")]
	private static extern c_int RngFree(void* rng);
}