using System;
using System.Interop;

namespace Cacti.Http;

static class WolfSSL {
	[CRepr]
	public struct Ctx : c_uint {}

	[CRepr]
	public struct ProtocolVersion {
		public c_uchar major;
		public c_uchar minor;
	}

	[CRepr]
	public struct Method {
		public ProtocolVersion version;
		public c_uchar side;
		public c_uchar downgrade;
	}

	[CRepr]
	public struct SSL : c_uint {}

	public enum VerfiyFormat : c_int {
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



	[LinkName("wolfSSL_Init")]
	public static extern c_int Init();

	[LinkName("wolfSSL_Cleanup")]
	public static extern c_int Cleanup();

	[LinkName("wolfTLS_client_method")]
	public static extern Method* ClientMethod();

	[LinkName("wolfSSL_get_error")]
	public static extern c_int GetError(Ctx* ctx, c_int ret);

	[LinkName("wolfSSL_ERR_error_string")]
	public static extern c_char* GetErrorString(c_int error, c_char* data);



	[LinkName("wolfSSL_CTX_new")]
	public static extern Ctx* CtxNew(Method* method);

	[LinkName("wolfSSL_CTX_load_verify_buffer")]
	public static extern c_int LoadVerifyBuffer(Ctx* ctx, c_char* data, c_long size, VerfiyFormat format);

	[LinkName("wolfSSL_CTX_set_verify")]
	public static extern void CtxSetVerify(Ctx* ctx, VerifyLevel level, VerifyCallback callback);

	[LinkName("wolfSSL_CTX_free")]
	public static extern void CtxFree(Ctx* ctx);



	[LinkName("wolfSSL_new")]
	public static extern SSL* New(Ctx* ctx);

	[LinkName("wolfSSL_UseSNI")]
	public static extern c_int UseSNI(SSL* ssl, c_uchar type, void* data, c_ushort size);

	[LinkName("wolfSSL_connect")]
	public static extern c_int Connect(SSL* ctx);

	[LinkName("wolfSSL_set_fd")]
	public static extern c_int SetFd(SSL* ssl, c_int fd);

	[LinkName("wolfSSL_write")]
	public static extern c_int Write(SSL* ssl, void* data, c_int size);

	[LinkName("wolfSSL_read")]
	public static extern c_int Read(SSL* ssl, void* data, c_int size);

	[LinkName("wolfSSL_free")]
	public static extern void Free(SSL* ssl);
}