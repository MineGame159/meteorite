using System;
using System.Threading;
using System.Collections;

namespace Cacti;

class ThreadPool {
	private List<Thread> threads ~ DeleteContainerAndItems!(_);
	private WaitEvent wait ~ delete _;

	private List<delegate void()> tasks ~ delete _;
	private Monitor monitor ~ delete _;

	private bool shuttingDown;

	public this(int count = 4) {
		threads = new .();
		wait = new .();

		tasks = new .();
		monitor = new .();

		// TODO: Don't hard code number of threads
		for (int i < count) {
			Thread t = new .(new => Run);
			t.SetName(scope $"Thread Pool - {i}");
			t.Start(false);

			threads.Add(t);
		}
	}

	public ~this() {
		using (monitor.Enter()) tasks.ClearAndDeleteItems();

		shuttingDown = true;
		wait.Set(true);

		for (Thread t in threads) t.Join();
	}

	public int TaskCount {
		get {
			int count = 0;
			using (monitor.Enter()) count = tasks.Count;
			return count;
		}
	};

	public void Add(delegate void() task) {
		using (monitor.Enter()) {
			tasks.Add(task);
			wait.Set();
		}
	}

	private void Run() {
		Tracy.RegisterCurrentThread();

		for (;;) {
			delegate void() task = null;

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