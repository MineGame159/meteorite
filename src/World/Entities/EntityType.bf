using System;

using Cacti;

namespace Meteorite {
	enum EntityGroup {
		Monster,
		Creature,
		Ambient,
		Water,
		Misc
	}

	class EntityType : IRegistryEntry {
		private ResourceKey key;
		private int32 id;

		public EntityGroup group;
		public double width, height;

		public ResourceKey Key => key;
		public int32 Id => id;

		[AllowAppend]
		public this(ResourceKey key, int32 id, EntityGroup group, double width, double height) {
			ResourceKey _key = append .(key);

			this.key = _key;
			this.id = id;

			this.group = group;
			this.width = width;
			this.height = height;
		}

		public Color GetColor() {
			switch (group) {
			case .Monster: return .(255, 25, 25);
			case .Creature: return .(25, 255, 25);
			case .Ambient: return .(25, 25, 25);
			case .Water: return .(25, 25, 255);
			case .Misc: return .(175, 175, 175);
			}
		}
	}
}