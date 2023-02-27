using System;

namespace Cacti;

interface ITask {
	void Run();
}

class DelegateTask : ITask {
	private delegate void() task ~ delete _;

	public this(delegate void() task) {
		this.task = task;
	}

	public void Run() {
		task();
	}
}