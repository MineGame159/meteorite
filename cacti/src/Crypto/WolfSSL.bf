using System;
using System.Interop;

namespace Cacti.Crypto;

static class WolfSSL {
	private static bool INITIALIZED = false;

	[LinkName("wolfSSL_lib_version")]
	private static extern c_char* _GetVersion();
	public static StringView GetVersion() => .(_GetVersion());

	[LinkName("wolfSSL_Init")]
	private static extern c_int _Init();
	public static Result<void> Init() {
		if (INITIALIZED) return .Ok;

		if (GetVersion() != "5.5.4") {
			Runtime.FatalError(scope $"WolfSSL library version mismatch, expected 5.5.4 but got {GetVersion()}");
		}

		INITIALIZED = true;
		return VoidResult!(_Init());
	}

	[LinkName("wolfSSL_Cleanup")]
	private static extern c_int _Cleanup();
	public static Result<void> Cleanup() => VoidResult!(_Cleanup());

	public static mixin VoidResult(c_int raw) {
		Result<void> result = .Err;
		
		if (raw >= 0) result = .Ok;

		result
	}

	public static mixin IntResult(c_int raw) {
		Result<int> result = .Err;
		
		if (raw >= 0) result = raw;

		result
	}
}