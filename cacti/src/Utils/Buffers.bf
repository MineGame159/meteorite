using System;
using System.Threading;
using System.Collections;

namespace Cacti {
	static class Buffers {
		private static List<Buffer> BUFFERS = new .() ~ DeleteContainerAndItems!(_);
		private static Monitor MONITOR = new .() ~ delete _;

		public static Buffer Get() {
			MONITOR.Enter();
			defer MONITOR.Exit();

			if (BUFFERS.IsEmpty) return new .();

			Buffer buffer = BUFFERS[BUFFERS.Count - 1];
			BUFFERS.RemoveAtFast(BUFFERS.Count - 1);
			return buffer;
		}

		public static void Return(Buffer buffer) {
			if (buffer == null) return;

			MONITOR.Enter();

			buffer.Clear();
			BUFFERS.Add(buffer);

			MONITOR.Exit();
		}
	}
}