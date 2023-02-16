using System;

namespace Meteorite;

class Registries {
	private Holder<Biome> biomes = .(BuiltinRegistries.BIOMES, false) ~ _.Dispose();
	private Biome[] biomeLookup = biomes.registry.CreateLookupTable() ~ delete _;

	public Registry<Biome> Biomes {
		get => biomes.registry;
		set {
			biomes.Dispose();
			biomes = .(value, true);

			delete biomeLookup;
			biomeLookup = value.CreateLookupTable();
		}
	}

	public Biome[] BiomeLookup => biomeLookup;

	struct Holder<T> : IDisposable where T : IRegistryEntry, delete {
		public Registry<T> registry;
		public bool owned;

		public this(Registry<T> registry, bool owned) {
			this.registry = registry;
			this.owned = owned;
		}

		public void Dispose() {
			if (owned) {
				delete registry;
			}
		}
	}
}