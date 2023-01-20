using System;
using System.Collections;

namespace Meteorite;

static class EntityAttributes {
	public const String GENERIC_MOVEMENT_SPEED = "minecraft:generic.movement_speed";
}

class EntityAttribute {
	public String name ~ delete _;
	public double baseValue;
	public List<EntityModifier> modifiers = new .() ~ delete _;

	public this(String name, double baseValue) {
		this.name = name;
		this.baseValue = baseValue;
	}
}

enum EntityModifierOperation {
	Add,
	MultiplyBase,
	MultiplyTotal
}

struct EntityModifier : this(EntityModifierOperation operation, double amount) {}