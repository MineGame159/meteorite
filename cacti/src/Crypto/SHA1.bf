using System;
using System.Interop;

namespace Cacti.Crypto;

class SHA1 {
	private uint8[104] handle;

	public this() {
		WolfSSL.VoidResult!(ShaInit(&handle));
	}

	public ~this() {
		WolfSSL.VoidResult!(ShaFree(&handle));
	}

	public Result<void> Update(Span<uint8> data) {
		return WolfSSL.VoidResult!(ShaUpdate(&handle, data.Ptr, (.) data.Length));
	}

	public Result<uint8[20]> Final() {
		uint8[20] hash = default;

		if (ShaFinal(&handle, &hash) < 0) {
			return .Err;
		}

		return hash;
	}
	
	[LinkName("wc_InitSha")]
	private static extern c_int ShaInit(void* sha);

	[LinkName("wc_ShaUpdate")]
	private static extern c_int ShaUpdate(void* sha, uint8* data, c_uint size);

	[LinkName("wc_ShaFinal")]
	private static extern c_int ShaFinal(void* sha, uint8* hash);

	[LinkName("wc_ShaFree")]
	private static extern c_int ShaFree(void* sha);
}