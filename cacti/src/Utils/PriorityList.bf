using System;
using System.Collections;

namespace Cacti {
	class PriorityList<T> : IEnumerable<T> {
		private List<Entry> entries = new .() ~ delete _;

		public void Add(T value, int priority = 0) {
			int i = 0;
			for (; i < entries.Count; i++) {
			    if (priority > entries[i].priority) break;
			}

			entries.Insert(i, Entry(value, priority));
		}

		public Enumerator GetEnumerator() => .(entries);

		struct Entry : this(T value, int priority) {}
		
		public struct Enumerator : IRefEnumerator<T*>, IEnumerator<T>, IResettable {
			private List<Entry>.Enumerator enumerator;

			public this(List<Entry> entries) {
				enumerator = entries.GetEnumerator();
			}

			public Result<T*> GetNextRef() mut {
				if (!enumerator.MoveNext()) return .Err;
				return &enumerator.CurrentRef.value;
			}

			public Result<T> GetNext() mut {
				if (!enumerator.MoveNext()) return .Err;
				return enumerator.Current.value;
			}

			public void Reset() mut => enumerator.Reset();
		}
	}
}