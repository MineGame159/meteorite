using System;

namespace Meteorite;

abstract class EntityModel {
	public float attackTime;
	public bool riding;
	public bool young = true;

	public abstract void SetupAnim(Entity entity, float limbSwing, float limbSwingAmount, float ageInTicks, float netHeadYaw, float headPitch);

	public void PrepareMobModel(Entity entity, float limbSwing, float limbSwingAmount, float partialTick) {}
}