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

	class EntityType {
		public String id ~ delete _;
		public EntityGroup group;
		public double width, height;

		public this(StringView id, EntityGroup group, double width, double height) {
			this.id = new .(id);
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