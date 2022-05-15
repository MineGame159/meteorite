using System;

namespace Meteorite {
	enum Direction {
		Up,
		Down,
		East, // Východ
		West, // Západ
		North, // Sever
		South // Juh
	}

	static class Utils {
		public static int CombineHashCode(int h1, int h2) => (((h1 << 5) + h1) ^ h2);

		public static int64 Lfloor(double value) {
		    int64 l = (.) value;
		    return value < (double) l ? l - 1L : l;
		}

		public static double Lerp(double delta, double start, double end) => start + delta * (end - start);

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
		
		public static int GetUsedMemory() {
#if BF_PLATFORM_WINDOWS
			ProcessMemoryCounters pmc = default;
			GetProcessMemoryInfo(Windows.GetCurrentProcess(), &pmc, sizeof(ProcessMemoryCounters));
			return (.) (pmc.workingSetSize / 1000000);
#else
			return 0;
#endif
		}
	}
}