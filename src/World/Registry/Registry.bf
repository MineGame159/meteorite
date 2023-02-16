using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite;

interface IRegistryEntry {
	ResourceKey Key { get; };

	int32 Id { get; };
}

class Registry<T> : IEnumerable<T> where T : IRegistryEntry, delete {
	private ResourceKey key;

	private Dictionary<ResourceKey, T> byKey = new .() ~ DeleteDictionaryAndValues!(_);
	private Dictionary<int32, T> byId = new .() ~ delete _;

	public ResourceKey Key => key;

	[AllowAppend]
	public this(ResourceKey key) {
		ResourceKey _key = append .(key);
		this.key = _key;
	}
	
	public T Register(T entry) {
		byKey[entry.Key] = entry;
		byId[entry.Id] = entry;

		return entry;
	}

	public T Get(ResourceKey key) => byKey.GetValueOrDefault(key);
	public T Get(int32 id) => byId.GetValueOrDefault(id);
	
	public Dictionary<ResourceKey, T>.ValueEnumerator GetEnumerator() => byKey.Values;

	public void Parse(Json json, delegate T(ResourceKey key, int32 id, Json json) factory) {
		// Clear entries
		for (T entry in this) {
			delete entry;
		}

		byKey.Clear();
		byId.Clear();
		
		// Parse
		for (let element in json.AsArray) {
			ResourceKey key = scope .(element["name"].AsString);
			int32 id = (.) element["id"].AsNumber;

			Register(factory(key, id, element["element"]));
		}
	}

	public void Parse(Tag tag, delegate T(ResourceKey key, int32 id, Tag tag) factory) {
		// Clear entries
		for (T entry in this) {
			delete entry;
		}

		byKey.Clear();
		byId.Clear();
		
		// Parse
		for (let element in tag.AsList) {
			ResourceKey key = scope .(element["name"].AsString);
			int32 id = (.) element["id"].AsInt;

			Register(factory(key, id, element["element"]));
		}
	}

	public T[] CreateLookupTable() {
		// Get the maximum id
		int32 maxId = 0;

		for (T entry in this) {
			if (entry.Id > maxId) maxId = entry.Id;
		}

		// Create the lookup table
		T[] table = new .[maxId + 1];

		for (T entry in this) {
			table[entry.Id] = entry;
		}

		// Check for holes
		for (int i < table.Count) {
			if (table[i] == null) {
				Log.Warning("Registry {} has an empty index {}", key, i);
			}
		}

		// Return
		return table;
	}
}