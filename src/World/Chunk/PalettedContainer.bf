using System;

using Cacti;

namespace Meteorite;

class PalettedContainer<T> {
	private IPalette<T> palette ~ delete _;
	private IBitStorage storage ~ delete _;

	private int edgeBits;

	public this(IPalette<T> palette, IBitStorage storage, int edgeBits) {
		this.palette = palette;
		this.storage = storage;
		this.edgeBits = edgeBits;

		storage.Upgrade = new => UpgradeStorage;
	}

	public int Count => 1 << edgeBits * 3;

	private mixin Index(int x, int y, int z) {
		(y << edgeBits | z) << edgeBits | x
	}

	public T Get(int x, int y, int z) {
		int32 id = storage.Get(Index!(x, y, z));
		return palette.GetValue(id);
	}

	public void Set(int x, int y, int z, T value) {
		int i = Index!(x, y, z);
		int32 id = palette.GetId(value);
		
		if (storage.Set(i, id)) {
			if (storage.Set(i, id)) Log.Error("Something went wrong. IBitStorage.Set() returned true twice in a row");
		}
	}

	private void UpgradeStorage(int bitsPerEntry) {
		BitStorage newStorage = new .(edgeBits, bitsPerEntry);
		newStorage.Upgrade = new => UpgradeStorage;

		for (int i < Count) newStorage.Set(i, storage.Get(i));

		delete storage;
		storage = newStorage;
	}
}