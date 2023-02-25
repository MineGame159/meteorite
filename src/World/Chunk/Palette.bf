using System;
using System.Collections;

namespace Meteorite;

interface IPalette<T> {
	T GetValue(int32 id);

	int32 GetId(T value);
}

class IndirectPalette<T> : IPalette<T> where T : IRegistryEntry {
	private T[] global;
	private List<int32> list ~ delete _;

	public this(T[] global, List<int32> list) {
		this.global = global;
		this.list = list;
	}

	public T GetValue(int32 id) {
		return global[list[id]];
	}

	public int32 GetId(T value) {
		for (int32 i < (.) list.Count) {
			if (list[i] == value.Id) return i;
		}

		list.Add(value.Id);
		return (.) list.Count - 1;
	}
}

class DirectPalette<T> : IPalette<T> where T : IRegistryEntry {
	private T[] global;

	public this(T[] global) {
		this.global = global;
	}

	public T GetValue(int32 id) => global[id];
	
	public int32 GetId(T value) => value.Id;
}