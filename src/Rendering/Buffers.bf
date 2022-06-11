using System;
using System.Collections;
using System.Threading;

namespace Meteorite{
	static class Buffers {
		public static WBuffer QUAD_INDICES ~ delete _;

		private static List<Buffer> BUFFERS = new .() ~ DeleteContainerAndItems!(_);
		private static Monitor MONITOR = new .() ~ delete _;

		public static Buffer Get() {
			MONITOR.Enter();
			defer MONITOR.Exit();

			if (BUFFERS.IsEmpty) return new .(1024);

			Buffer buffer = BUFFERS[BUFFERS.Count - 1];
			BUFFERS.RemoveAtFast(BUFFERS.Count - 1);
			return buffer;
		}

		public static void Return(Buffer buffer) {
			if (buffer == null) return;

			MONITOR.Enter();

			BUFFERS.Add(buffer);

			MONITOR.Exit();
		}

		public static void CreateGlobalIndices() {
			const int count = 8192 * 32;
			uint32* buffer = new uint32[6 * count]*;
			uint32 v = 0;

			for (int i < count) {
				uint32 i1 = v++;
				uint32 i2 = v++;
				uint32 i3 = v++;
				uint32 i4 = v++;

				buffer[i * 6] = i1;
				buffer[i * 6 + 1] = i2;
				buffer[i * 6 + 2] = i3;

				buffer[i * 6 + 3] = i3;
				buffer[i * 6 + 4] = i4;
				buffer[i * 6 + 5] = i1;
			}

			QUAD_INDICES = Gfx.CreateBuffer(.Index, 6 * count * 4, buffer);
			delete buffer;
		}
	}
}