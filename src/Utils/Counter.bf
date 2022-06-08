using System;

namespace Meteorite {
	class Counter<T> where T : operator T + T {
		private T[] values ~ delete _;
		private int i;

		public this(int size) {
			values = new .[size];
		}

		public void Add(T value) {
			values[i++] = value;

			if (i >= values.Count) i = 0;
		}

		public T Get() {
			T count = default;

			for (let value in values) count += value;

			return count;
		}
	}
}