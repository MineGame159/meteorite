using System;
using System.Threading;
using System.Collections;

namespace Meteorite {
	class ThreadExecutor {
		public delegate void Task();

		private Thread t ~ delete _;
		private WaitEvent wait ~ delete _;
		private Monitor monitor ~ delete _;
		private List<Task> tasks ~ delete _;

		private bool shuttingDown;

		public this(String name) {
			wait = new .();
			monitor = new .();
			tasks = new .();

			t = new .(new => Run);
			t.SetName(name);
			t.Start(false);
		}

		public ~this() {
			shuttingDown = true;
			wait.Set();

			t.Join();
		}

		public int TaskCount {
			get {
				int count = 0;
				using (monitor.Enter()) count = tasks.Count;
				return count;
			}
		};

		public void Add(Task task) {
			using (monitor.Enter()) {
				tasks.Add(task);
				wait.Set();
			}
		}

		private void Run() {
			for (;;) {
				Task task = null;

				using (monitor.Enter()) {
					if (tasks.Count > 0) task = tasks.PopFront();
				}

				if (task == null) {
					wait.WaitFor();
					if (shuttingDown) break;
					continue;
				}

				task();
				delete task;
			}
		}
	}
}