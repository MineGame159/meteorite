using System;

namespace Cacti;

class Average<T> where T : const int {
	private double[T] values;
	private int size, i;

	public void Add(double value) {
		values[i++] = value;

		if (i >= T) i = 0;
		if (size < T) size++;
	}

	public double Get() {
		double total = 0;

		for (int i < size) {
			total += values[i];
		}

		return total / size;
	}
}