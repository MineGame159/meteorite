using System;
using System.Interop;

namespace Cacti.Crypto;

class Crypto {
	[CRepr]
	private struct ProtocolVersion {
		public c_uchar major;
		public c_uchar minor;
	}

	[CRepr]
	private struct Method {
		public ProtocolVersion version;
		public c_uchar side;
		public c_uchar downgrade;
	}

	public enum VerifyFormat : c_int {
		ASN1	= 2,
		PEM		= 1
	}

	public enum VerifyLevel : c_int {
		None				= 0,
		Peer				= 1 << 0,
		FailIfNoPeerCert	= 1 << 1,
		ClientOnce			= 1 << 2,
		PostHandshake		= 1 << 3,
		FailEexceptPSK		= 1 << 4,
		Default				= 1 << 9,
	}

	public typealias VerifyCallback = function c_int(c_int preverify, void* store);

	private c_uint* handle;

	public this() {
		WolfSSL.Init();

		handle = CtxNew(ClientMethod());
		Runtime.Assert(handle != null, "Failed to create Crypto instance");
	}

	public ~this() {
		CtxFree(handle);
	}

	public Result<void> LoadVerifyBuffer(StringView data, VerifyFormat format) {
		return WolfSSL.VoidResult!(CtxLoadVerifyBuffer(handle, data.Ptr, (.) data.Length, format));
	}

	public void SetVerify(VerifyLevel level, VerifyCallback callback) {
		CtxSetVerify(handle, level, callback);
	}

	[LinkName("wolfTLS_client_method")]
	private static extern Method* ClientMethod();

	[LinkName("wolfSSL_CTX_new")]
	public static extern c_uint* CtxNew(Method* method);

	[LinkName("wolfSSL_CTX_load_verify_buffer")]
	public static extern c_int CtxLoadVerifyBuffer(void* ctx, c_char* data, c_long size, VerifyFormat format);

	[LinkName("wolfSSL_CTX_set_verify")]
	public static extern void CtxSetVerify(void* ctx, VerifyLevel level, VerifyCallback callback);

	[LinkName("wolfSSL_CTX_free")]
	public static extern void CtxFree(void* ctx);
}