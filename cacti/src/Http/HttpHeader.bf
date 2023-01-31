using System;

namespace Cacti.Http;

enum HttpHeaderName {
	// Authentication
	case WWWAuthenticate,
		 Authorization,
		 ProxyAuthenticate,
		 ProxyAuthorization,

	// Caching
		 Age,
		 CacheControl,
		 ClearSiteData,
		 Expires,
		 Pragma,
		 Warning,

	// Client hints
		 AcceptCH,
		 AcceptCHLifetime,
		 CriticalCH,

	// User agent client hints
		 SetCHPrefersReducedMotion,
		 SecCHUA,
		 SecCHUAArch,
		 SecCHUABitness,
		 SecCHUAFullVersionList,
		 SecCHUAMobile,
		 SecCHUAModel,
		 SecCHUAPlatform,
		 SecCHUAPlatformVersion,

	// Device client hintsň
		 ConcentDPR,
		 DeviceMemory,
		 DPR,
		 ViewportWidth,
		 Width,

	// Network client hints
		 Downlink,
		 ECT,
		 RTT,
		 SaveData,

	// Conditionals
		 LastModifier,
		 ETag,
		 IfMatch,
		 IfNoneMatch,
		 IfModifiedSince,
		 IfUnmodifiedSince,
		 Vary,

	// Connection management
		 Connection,
		 KeepAlive,

	// Content negotiation
		 Accept,
		 AcceptEncoding,
		 AcceptLanguage,

	// Controls
		 Expect,
		 MaxForwards,

	// Cookies
		 Cookie,
		 SetCookie,

	// CORS
		 AccessControlAllowOrigin,
		 AccessControlAllowCredentials,
		 AccessControlAllowHeaders,
		 AccessControlAllowMethods,
		 AccessControlExposeHeaders,
		 AccessControlMaxAge,
		 AccessControlRequestHeaders,
		 AccessControlRequestMethod,
		 Origin,
		 TimingAllowOrigin,

	// Downloads
		 ContentDisposition,

	// Message body information
		 ContentLength,
		 ContentType,
		 ContentEncoding,
		 ContentLanguage,
		 ContentLocation,

	// Proxies
		 Forwarded,
		 XForwardedFor,
		 XForwardedHost,
		 XForwardedProto,
		 Via,

	// Redirects
		 Location,
		 Refresh,

	// Request context
		 From,
		 Host,
		 Referer,
		 ReferrerPolicy,
		 UserAgent,

	// Response context
		 Allow,
		 Server,

	// Range requests
		 AcceptRanges,
		 Range,
		 IfRange,
		 ContentRange,

	// Security
		 CrossOriginEmbedderPolicy,
		 CrossOriginOpenerPolicy,
		 CrossOriginResourcePolicy,
		 ContentSecurityPolicy,
		 ContentSecurityPolicyReportOnly,
		 ExpectCT,
		 OriginIsolation,
		 PermissionsPolicy,
		 StrictTransportSecurity,
		 UpgradeInsecureRequests,
		 XContentTypeOptions,
		 XDownloadOptions,
		 XFrameOptions,
		 XPermittedCrossDomainPolicies,
		 XPoweredBy,
		 XXSSProtection,

	// Fetch metadata request headers
		 SecFetchSite,
		 SecFetchMode,
		 SecFetchUser,
		 SecFetchDest,
		 ServiceWorkerNavigationPreload,

	// Server-sent events
		 LastEventID,
		 NEL,
		 PingFrom,
		 PingTo,
		 ReportTo,

	// Transfer coding
		 TransferEncoding,
		 TE,
		 Trailer,

	// WebSockets
		 SecWebSocketKey,
		 SecWebSocketExtensions,
		 SecWebSocketAccept,
		 SecWebSocketProtocol,
		 SecWebSocketVersion,

	// Other
		 AcceptPushPolicy,
		 AcceptSignature,
		 AltSvc,
		 Date,
		 EarlyData,
		 LargeAllocation,
		 Link,
		 PushPolicy,
		 RetryAfter,
		 Signature,
		 SignedHeaders,
		 ServerTiming,
		 ServiceWorkerAllowed,
		 SourceMap,
		 Upgrade,
		 XDNSPrefetchControl,
		 XFirefoxSpdy,
		 XPingback,
		 XRequestedWith,
		 XRobotsTag,
		 XUACompatible;

	public StringView Name => NameGetter.GetName(this);

	public static Result<Self> Parse(StringView string) {
		for (let header in Enum.GetValues<Self>()) {
			if (header.Name.Equals(string, true)) {
				return header;
			}
		}

		return .Err;
	}

	private static class NameGetter {
		[OnCompile(.TypeInit), Comptime]
		public static void Generate() {
			Compiler.EmitTypeBody(typeof(Self), """
				public static StringView GetName(HttpHeaderName header) {
					switch (header) {\n
				""");

			for (let header in Enum.GetValues<HttpHeaderName>()) {
				String enumName = header.ToString(.. scope .());
				String name = scope .(enumName.Length + 4);

				switch (header) {
				case .ConcentDPR:			name.Set("Content-DPR");
				case .LastEventID:			name.Set("Last-Event-ID");
				case .XDNSPrefetchControl:	name.Set("X-DNS-Prefetch-Control");
				case .XUACompatible:		name.Set("X-UA-Compatible");
				case .XXSSProtection:		name.Set("X-XSS-Protection");
				case .ExpectCT:				name.Set("Expect-CT");
				default:
					for (let char in enumName.RawChars) {
						if (char.IsUpper && !name.IsEmpty && (@char.Index + 1 < enumName.Length && enumName[@char.Index + 1].IsLower)) name.Append('-');
						name.Append(char);
					}

					name.Replace("CH", "-CH");
					name.Replace("UA", "-UA");
				}

				Compiler.EmitTypeBody(typeof(Self), scope $"	case .{header}: return \"{name}\";\n");
			}

			Compiler.EmitTypeBody(typeof(Self), """
					}
				}
				""");
		}
	}
}