using System;
using System.IO;
using System.Interop;
using System.Collections;
using System.Diagnostics;

using GLFW;
using Bulkan;

namespace Cacti {
	static class Utils {
		public static Random RANDOM = new .() ~ delete _;

		[NoDiscard]
		public static int CombineHashCode(int h1, int h2) => (((h1 << 5) + h1) ^ h2);

		public static void CombineHashCode(ref int hash, int other) => hash = CombineHashCode(hash, other);

		public static void CombineHashCode<T>(ref int hash, T other) where T : IHashable => hash = CombineHashCode(hash, other.GetHashCode());

		public static T Lerp<T>(T delta, T start, T end) where T : operator T - T, operator T * T, operator T + T {
			return start + delta * (end - start);
		}

		public static int64 Lfloor(double value) {
		    int64 l = (.) value;
		    return value < (double) l ? l - 1L : l;
		}

		public static double FractionalPart(double value) {
		    return value - (double) Lfloor(value);
		}

		public static int FloorDiv(int x, int y) {
		    int r = x / y;
		    // if the signs are different and modulo not zero, round down
		    if ((x ^ y) < 0 && (r * y != x)) {
		        r--;
		    }
		    return r;
		}

		public static int PositiveCeilDiv(int x, int y) {
			return -FloorDiv(-x, y);
		}

		public static int64 GetSeed(int x, int y, int z) {
			int64 l = (.) (x * 3129871) ^ (.) z * 116129781L ^ (.) y;
			l = l * l * 42317861L + l * 11L;
			return l >> 16;
		}

		public static int64 UnixTimeEpoch { get {
			TimeSpan time = DateTime.Now.Subtract(DateTime(1970, 1, 1));
			return time.Ticks / TimeSpan.TicksPerSecond;
		} }

		public static LineEnumerator Lines(StringView string, bool removeEmpty = true) {
			return .(string.Split('\n', removeEmpty ? .RemoveEmptyEntries : 0));
		}

		public static (uint8, bool) HexToByte(char8 x1, char8 x2) {
			uint8 b1 = HEX_TO_BYTE[x1];
			uint8 b2 = HEX_TO_BYTE[x2];

			return ((b1 << 4) | b2, b1 != 255 && b2 != 255);
		}

		public static int HexEncode(Span<uint8> bytes, String str) {
			int i = 0;

			for (uint8 v in bytes) {
				str.Append(HEX_TABLE[v >> 4]);
				str.Append(HEX_TABLE[v & 0x0F]);

				i += 2;
			}

			return i;
		}

		public static void CombinePath(String target, StringView rest) {
			// Collect all components into a single list
			List<StringView> components = scope .();

			for (let component in target.Split(scope char8[] ('/', '\\'), .RemoveEmptyEntries)) {
				components.Add(scope:: String(component));
			}

			for (let component in rest.Split(scope char8[] ('/', '\\'), .RemoveEmptyEntries)) {
				components.Add(component);
			}

			// Remove .. components
			for (int i < components.Count) {
				StringView component = components[i];

				if (component == ".." && i > 0) {
					components.RemoveAt(i);
					components.RemoveAt(i - 1);

					i -= 2;
				}
			}

			// Combine
			target.Clear();

			for (let component in components) {
				if (target.Length > 0 && !target.EndsWith('\\') && !target.EndsWith('/')) {
					target.Append(Path.DirectorySeparatorChar);
				}

				target.Append(component);
			}
		}

		public static int ReverseComparison(int comp) {
			if (comp == 0) return 0;
			return comp > 0 ? -1 : 1;
		}
		
		public static void OpenUrl(StringView url) {
			ProcessStartInfo info = scope .();

#if BF_PLATFORM_WINDOWS
			info.SetFileName(url);
#elif BF_PLATFORM_LINUX
			info.SetFileName("xdg-open");
			info.SetArguments(scope $"\"{url}\"");
#else
			Log.Error("Cannot open URLs on this platform: {}", url);
			return;
#endif

			SpawnedProcess process = scope .();

			if (process.Start(info) == .Err) {
				Log.Error("Failed to open URL: {}", url);
				return;
			}

			process.WaitFor();
		}

		public static int GetNullableHashCode<T>(T? nulable) where T : struct, IHashable {
			return nulable.HasValue ? nulable.Value.GetHashCode() : 159;
		}

		public static T SwapBytes<T>(T value) where T : struct {
#unwarn
			uint8* bytes = (.) &value;

			uint8[sizeof(T)] newBytes = ?;
			for (int i < sizeof(T)) {
				newBytes[i] = bytes[sizeof(T) - 1 - i];
			}

			return *(T*) &newBytes;
		}

#if BF_PLATFORM_WINDOWS
		[CRepr]
		struct ProcessMemoryCounters {
			public int32 cb;
			public int32 pageFaultCount;
			public uint peakWorkingSetSize;
			public uint workingSetSize;
			public uint quotaPeakPagedPoolUsage;
			public uint quotaPagedPoolUsage;
			public uint quotaPeakNonPagedPoolUsage;
			public uint quotaNonPagedPoolUsage;
			public uint pagefileUsage;
			public uint peakPagefileUsage;
		}

		[Import("Psapi.dll"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool GetProcessMemoryInfo(Windows.Handle handle, ProcessMemoryCounters* ppsmemCounters, uint32 cb);
#endif

		public static int UsedMemory { get {
#if BF_PLATFORM_WINDOWS
			ProcessMemoryCounters pmc = default;
			GetProcessMemoryInfo(Windows.GetCurrentProcess(), &pmc, sizeof(ProcessMemoryCounters));
			return (.) (pmc.workingSetSize / 1000000);
#else
			return 0;
#endif
		} }

		private const uint8[?] HEX_TO_BYTE = .(
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 255, 255,
			255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
		);

		private const String HEX_TABLE = "0123456789abcdef";
	}

	interface IPool<T> {
		T Get();
		
		void Put(T object);
	}
}

static {
	public static mixin DisposeAndNullify(var val) {
		if (val != null) {
			val.Dispose();
			val = null;
		}
	}

	public static mixin ReleaseAndNullify(var val) {
		if (val != null) {
			val.Release();
			val = null;
		}
	}
}