using System;
using System.Interop;
using System.Threading;
using System.Reflection;

namespace Cacti;

static class Tracy {
	public const bool ONLY_EMIT_WHEN_CONNECTED = true;

	public static BumpAllocator LOCATION_ALLOCATOR = new .() ~ delete _;

	[CRepr]
	public struct Location {
	    public c_char* name;
	    public c_char* func;
	    public c_char* file;
	    public uint32 line;
	    public uint32 color;

		public static Self Alloc(IRawAllocator alloc, StringView name, StringView func, StringView file, int line, uint32 color) {
			mixin AllocStr(StringView str) {
				c_char* raw = new:alloc .[str.Length + 1]* (?);
				str.CopyTo(.(raw, str.Length));
				raw[str.Length] = '\0';

				raw
			}

			return .() {
				name = AllocStr!(name),
				func = AllocStr!(func),
				file = AllocStr!(file),
				line = (.) line,
				color = color
			};
		}
	};

	[CRepr]
	struct ZoneCtx {
		public uint32 id;
		public c_int active;
	}

	[CLink]
	private static extern void ___tracy_startup_profiler();

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static void Startup() => ___tracy_startup_profiler();

	[CLink]
	private static extern void ___tracy_shutdown_profiler();

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static void Shutdown() => ___tracy_shutdown_profiler();

	[CLink]
	private static extern void ___tracy_set_thread_name(c_char* name);

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static void RegisterCurrentThread() {
		String name = Thread.CurrentThread.GetName(.. scope .());
		___tracy_set_thread_name(name.CStr());
	}

	[CLink]
	private static extern void ___tracy_emit_frame_mark(c_char* name);

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static void Frame(StringView name = "") => ___tracy_emit_frame_mark(name.IsEmpty ? null : name.ToScopeCStr!());
	
	[CLink]
	private static extern uint64 ___tracy_alloc_srcloc_name(uint32 line, c_char* source, c_size sourceSz, c_char* func, c_size functionSz, c_char* name, c_size nameSz);

	[CLink]
	private static extern ZoneCtx ___tracy_emit_zone_begin(Location* srcloc, c_int active);

	[CLink]
	private static extern ZoneCtx ___tracy_emit_zone_begin_alloc(uint64 location, c_int active);

	[CLink]
	private static extern void ___tracy_emit_zone_end(ZoneCtx ctx);

	[CLink]
	private static extern void ___tracy_emit_zone_text(ZoneCtx ctx, c_char* txt, c_size size);

	[CLink]
	private static extern void ___tracy_emit_message(c_char* txt, c_size size, c_int callback);

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static void Message(StringView msg) {
		if (!ONLY_EMIT_WHEN_CONNECTED || IsConnected()) {
			___tracy_emit_message(msg.Ptr, (.) msg.Length, 0);
		}
	}

	[CLink]
	private static extern c_int ___tracy_connected();

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static bool IsConnected() => ___tracy_connected() != 0;

	public struct Zone : IDisposable {
		private ZoneCtx ctx = default;
		private bool emitted = false;

		public this(Location* location) {
#if CACTI_TRACY
			if (!ONLY_EMIT_WHEN_CONNECTED || IsConnected()) {
				this.ctx = ___tracy_emit_zone_begin(location, 1);
				this.emitted = true;
			}
#endif
		}

		public this(uint64 location) {
#if CACTI_TRACY
			if (!ONLY_EMIT_WHEN_CONNECTED || IsConnected()) {
				this.ctx = ___tracy_emit_zone_begin_alloc(location, 1);
				this.emitted = true;
			}
#endif
		}

#if !CACTI_TRACY
		[SkipCall]
#endif
		public void AddText(StringView text) {
			if (emitted) {
				___tracy_emit_zone_text(ctx, text.Ptr, (.) text.Length);
			}
		}

#if !CACTI_TRACY
		[SkipCall]
#endif
		public void Dispose() {
			if (emitted) {
				___tracy_emit_zone_end(ctx);
			}
		}
	}

	private static mixin GetFunctionName(String member) {
		StringView func = member.Substring(0, member.IndexOf('('));
		func = func.Substring(func.LastIndexOf('.') + 1);

		func
	}

	private static mixin GetFinalName(String type, StringView func) {
		scope:mixin $"{type.Substring(type.LastIndexOf('.') + 1)}.{func}"
	}
		 
#if !CACTI_TRACY
	[SkipCall]
#endif
	[Optimize]
	public static uint64 GetLocation(StringView name = "", String file = Compiler.CallerFileName, String type = Compiler.CallerTypeName, String member = Compiler.CallerMemberName, int line = Compiler.CallerLineNum) {
		StringView func = GetFunctionName!(member);

		if (name.IsEmpty) {
			String finalName = GetFinalName!(type, func);
			
			return ___tracy_alloc_srcloc_name(
				(.) line,
				file.Ptr,
				(.) file.Length,
				func.Ptr,
				(.) func.Length,
				finalName.Ptr,
				(.) finalName.Length
			);
		}
		else {
			return ___tracy_alloc_srcloc_name(
				(.) line,
				file.Ptr,
				(.) file.Length,
				func.Ptr,
				(.) func.Length,
				name.Ptr,
				(.) name.Length
			);
		}
	}

#if !CACTI_TRACY
	[SkipCall]
#endif
	[Optimize]
	public static Location AllocLocation(StringView name = "", IRawAllocator alloc = LOCATION_ALLOCATOR, String file = Compiler.CallerFileName, String type = Compiler.CallerTypeName, String member = Compiler.CallerMemberName, int line = Compiler.CallerLineNum) {
		StringView finalFile = file;

		if (finalFile.Contains(':')) {
			finalFile = finalFile.Substring(file.IndexOf(':') + 1);
		}

		StringView func = GetFunctionName!(member);

		if (name.IsEmpty) {
			return .Alloc(alloc, GetFinalName!(type, func), func, finalFile, line, 0);
		}

		return .Alloc(alloc, name, func, finalFile, line, 0);
	}

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static mixin Scoped(Location* location) {
		Zone zone = .(location);
		defer:mixin zone.Dispose();

		zone
	}

#if !CACTI_TRACY
	[SkipCall]
#endif
	public static mixin Scoped(uint64 location) {
		Zone zone = .(location);
		defer:mixin zone.Dispose();

		zone
	}

	[AttributeUsage(.Method | .Constructor)]
	public struct Profile : Attribute, IOnMethodInit {
		public StringView name;
		public bool variable;

		public this(StringView name = "", bool variable = false) {
			this.name = name;
			this.variable = variable;
		}

		[Comptime]
		public void OnMethodInit(MethodInfo methodInfo, Self* prev) mut {
#if CACTI_TRACY
			Compiler.EmitMethodEntry(methodInfo, scope $"""
				static Cacti.Tracy.Location __tracy_zone_location = default;
				if (__tracy_zone_location == default) __tracy_zone_location = Cacti.Tracy.AllocLocation("{name}");

				""");

			if (variable) {
				Compiler.EmitMethodEntry(methodInfo, "Cacti.Tracy.Zone __tracy_zone = Cacti.Tracy.Scoped!(&__tracy_zone_location);");
			}
			else {
				Compiler.EmitMethodEntry(methodInfo, "Cacti.Tracy.Scoped!(&__tracy_zone_location);");
			}
#else
			if (variable) {
				Compiler.EmitMethodEntry(methodInfo, "Cacti.Tracy.Zone __tracy_zone = ?;");
			}
#endif
		}
	}
}