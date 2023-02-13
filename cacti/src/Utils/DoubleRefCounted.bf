using System;
using System.Threading;
using System.Diagnostics;

namespace Cacti;

abstract class DoubleRefCounted : IRefCounted {
	private int refCount = 1;
	private int weakRefCount = 0;

	public bool NoReferences => refCount == 0;

	public ~this() {
		Debug.Assert(refCount == 0 && weakRefCount == 0);
	}

	protected abstract void Delete();

	public void AddRef() {
		Interlocked.Increment(ref refCount);
	}

	public void AddWeakRef() {
		Interlocked.Increment(ref weakRefCount);
	}

	public void Release() {
		Interlocked.Decrement(ref refCount);
		CheckForDelete();
	}

	public void ReleaseWeak() {
		Interlocked.Decrement(ref weakRefCount);
		CheckForDelete();
	}

	private void CheckForDelete() {
		if (refCount == 0 && weakRefCount == 0) Delete();
	}
}