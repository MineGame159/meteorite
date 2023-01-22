using System;
using System.Collections;

namespace Meteorite {
	class MyRegistry<T> : IEnumerable<T> where T : delete {
		private Dictionary<String, T> registry = new .() ~ DeleteDictionaryAndValues!(_);

		public T Register(String id, T value) {
			registry[id] = value;
			return value;
		}

		public T Get(String id) {
			return registry.GetValueOrDefault(id);
		}

		public Dictionary<String, T>.ValueEnumerator GetEnumerator() {
			return registry.Values;
		}
	}

	static class Registry {
		public static MyRegistry<Block> BLOCKS = new .() ~ delete _;
		public static MyRegistry<Item> ITEMS = new .() ~ delete _;
		public static MyRegistry<EntityType> ENTITY_TYPES = new .() ~ delete _;
	}
}