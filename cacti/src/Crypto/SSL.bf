using System;
using System.Net;
using System.Interop;

namespace Cacti.Crypto;

class SSL {
	private c_uint* handle;

	public this(Crypto crypto) {
		handle = SslNew(crypto.[Friend]handle);
		Runtime.Assert(handle != null, "Failed to create SSL instance");
	}

	public ~this() {
		SslFree(handle);
	}

	public Result<void> UseSNI(c_uchar type, Span<uint8> data) {
		return WolfSSL.VoidResult!(SslUseSNI(handle, type, data.Ptr, (.) data.Length));
	}

	public Result<void> Connect() {
		return WolfSSL.VoidResult!(SslConnect(handle));
	}

	public Result<void> SetSocket(Socket socket) {
		return WolfSSL.VoidResult!(SslSetFd(handle, (.) socket.NativeSocket));
	}

	public Result<int> Write(Span<uint8> data) {
		return WolfSSL.IntResult!(SslWrite(handle, data.Ptr, (.) data.Length));
	}

	public Result<int> Read(Span<uint8> data) {
		return WolfSSL.IntResult!(SslRead(handle, data.Ptr, (.) data.Length));
	}

	[LinkName("wolfSSL_new")]
	public static extern c_uint* SslNew(void* ctx);

	[LinkName("wolfSSL_UseSNI")]
	public static extern c_int SslUseSNI(void* ssl, c_uchar type, void* data, c_ushort size);

	[LinkName("wolfSSL_set_fd")]
	public static extern c_int SslSetFd(void* ssl, c_int fd);

	[LinkName("wolfSSL_connect")]
	public static extern c_int SslConnect(void* ctx);

	[LinkName("wolfSSL_write")]
	public static extern c_int SslWrite(void* ssl, void* data, c_int size);

	[LinkName("wolfSSL_read")]
	public static extern c_int SslRead(void* ssl, void* data, c_int size);

	[LinkName("wolfSSL_free")]
	public static extern void SslFree(void* ssl);
}