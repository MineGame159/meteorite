using System;

namespace Meteorite {
	enum Direction {
		case Up;
		case Down;
		case East; // Východ
		case North; // Sever
		case West; // Západ
		case South; // Juh

		public Vec3i GetOffset() {
			switch (this) {
			case .Up:    return .(0, 1, 0);
			case .Down:  return .(0, -1, 0);
			case .East:  return .(1, 0, 0);
			case .West:  return .(-1, 0, 0);
			case .North: return .(0, 0, -1);
			case .South: return .(0, 0, 1);
			}
		}

		public Direction GetOpposite() {
			switch (this) {
			case .Up:    return .Down;
			case .Down:  return .Up;
			case .East:  return .West;
			case .West:  return .East;
			case .North: return .South;
			case .South: return .North;
			}
		}

		public int Data2D { get {
			switch (this) {
			case .Up, .Down: return -1;

			case .East:  return 3;
			case .North: return 2;
			case .West:  return 1;
			case .South: return 0;
			}
		} }

		public int YRot => (Data2D & 3) * 90;
	}

	static class Utils {
		public static int CombineHashCode(int h1, int h2) => (((h1 << 5) + h1) ^ h2);

		public static int64 Lfloor(double value) {
		    int64 l = (.) value;
		    return value < (double) l ? l - 1L : l;
		}

		public static double FractionalPart(double value) {
		    return value - (double) Lfloor(value);
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