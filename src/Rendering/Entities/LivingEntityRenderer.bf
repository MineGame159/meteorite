using System;

namespace Meteorite {
	abstract class LivingEntityRenderer : EntityRenderer {
		protected EntityModel model ~ delete _;

		public this(EntityModel model) {
			this.model = model;
		}

		public override void Render(MatrixStack matrices, Entity entity, NamedMeshBuilderProvider provider, float tickDelta) {
			/*matrices.pushPose();
			this.model.attackTime = this.getAttackAnim(entity, partialTicks);
			this.model.riding = entity.isPassenger();
			this.model.young = entity.isBaby();
			float f = Mth.rotLerp(partialTicks, entity.yBodyRotO, entity.yBodyRot);
			float g = Mth.rotLerp(partialTicks, entity.yHeadRotO, entity.yHeadRot);
			float h = g - f;
			if (entity.isPassenger() && entity.getVehicle() instanceof LivingEntity livingEntity) {
				f = Mth.rotLerp(partialTicks, livingEntity.yBodyRotO, livingEntity.yBodyRot);
				h = g - f;
				float i = Mth.wrapDegrees(h);
				if (i < -85.0F) {
					i = -85.0F;
				}

				if (i >= 85.0F) {
					i = 85.0F;
				}

				f = g - i;
				if (i * i > 2500.0F) {
					f += i * 0.2F;
				}

				h = g - f;
			}

			float j = Mth.lerp(partialTicks, entity.xRotO, entity.getXRot());
			if (isEntityUpsideDown(entity)) {
				j *= -1.0F;
				h *= -1.0F;
			}

			if (entity.getPose() == Pose.SLEEPING) {
				Direction direction = entity.getBedOrientation();
				if (direction != null) {
					float k = entity.getEyeHeight(Pose.STANDING) - 0.1F;
					matrices.translate((double)((float)(-direction.getStepX()) * k), 0.0, (double)((float)(-direction.getStepZ()) * k));
				}
			}

			float i = this.getBob(entity, partialTicks);
			this.setupRotations(entity, matrices, i, f, partialTicks);
			matrices.scale(-1.0F, -1.0F, 1.0F);
			this.scale(entity, matrices, partialTicks);
			matrices.translate(0.0, -1.501F, 0.0);
			float k = 0.0F;
			float l = 0.0F;
			if (!entity.isPassenger() && entity.isAlive()) {
				k = Mth.lerp(partialTicks, entity.animationSpeedOld, entity.animationSpeed);
				l = entity.animationPosition - entity.animationSpeed * (1.0F - partialTicks);
				if (entity.isBaby()) {
					l *= 3.0F;
				}

				if (k > 1.0F) {
					k = 1.0F;
				}
			}

			this.model.prepareMobModel(entity, l, k, partialTicks);
			this.model.setupAnim(entity, l, k, i, h, j);
			Minecraft minecraft = Minecraft.getInstance();
			boolean bl = this.isBodyVisible(entity);
			boolean bl2 = !bl && !entity.isInvisibleTo(minecraft.player);
			boolean bl3 = minecraft.shouldEntityAppearGlowing(entity);
			RenderType renderType = this.getRenderType(entity, bl, bl2, bl3);
			if (renderType != null) {
				VertexConsumer vertexConsumer = buffer.getBuffer(renderType);
				int m = getOverlayCoords(entity, this.getWhiteOverlayProgress(entity, partialTicks));
				this.model.renderToBuffer(matrices, vertexConsumer, packedLight, m, 1.0F, 1.0F, 1.0F, bl2 ? 0.15F : 1.0F);
			}

			if (!entity.isSpectator()) {
				for(RenderLayer<T, M> renderLayer : this.layers) {
					renderLayer.render(matrices, buffer, packedLight, entity, l, k, partialTicks, i, h, j);
				}
			}

			matrices.popPose();
			super.render(entity, entityYaw, partialTicks, matrices, buffer, packedLight);*/
		}

		protected virtual void SetupRotations(Entity entity, MatrixStack matrices, float ageInTicks, float rotationYaw, float partialTicks) {
			var rotationYaw;

			if (IsShaking(entity)) {
				rotationYaw += (Math.Cos(entity.tickCount * 3.25f) * Math.PI_f * 0.4f);
			}

			if (entity.pose != .Sleeping) {
				matrices.Rotate(.(0, 1, 0), 180 - rotationYaw);
			}

			/*if (entity.deathTime > 0) {
				float f = (entity.deathTime + partialTicks - 1f) / 20f * 1.6f;
				f = Math.Sqrt(f);
				if (f > 1f) f = 1f;

				matrices.Rotate(.(0, 0, 1), f * GetFlipDegrees(entity));
			} else if (entity.isAutoSpinAttack()) {
				matrices.Rotate(.(1, 0, 0), -90 - entity.pitch);
				matrices.Rotate(.(0, 1, 0), (entity.tickCount + partialTicks) * -75f);
			} else if (entity.pose == .Sleeping) {
				/*Direction direction = entity.GetBedOrientation();
				float g = direction != null ? SleepDirectionToRotation(direction) : rotationYaw;
				matrices.Rotate(.(0, 0, 1), g);
				matrices.Rotate(.(0, 0, 1), GetFlipDegrees(entity));
				matrices.Rotate(.(0, 1, 0), 270);*/
			} else*/ if (IsEntityUpsideDown(entity)) {
				matrices.Translate(.(0, (.) entity.type.height + 0.1f, 0));
				matrices.Rotate(.(0, 0, 1), 180);
			}
		}

		protected virtual float GetFlipDegrees(Entity entity) => 90;

		protected virtual bool IsShaking(Entity entity) => false;

		public static bool IsEntityUpsideDown(Entity entity) {
			/*if (livingEntity instanceof Player || livingEntity.hasCustomName()) {
				String string = ChatFormatting.stripFormatting(livingEntity.getName().getString());
				if ("Dinnerbone".equals(string) || "Grumm".equals(string)) {
					return !(livingEntity instanceof Player) || ((Player)livingEntity).isModelPartShown(PlayerModelPart.CAPE);
				}
			}*/

			return false;
		}

		private static float SleepDirectionToRotation(Direction facing) {
			switch(facing) {
				case .South: return 90;
				case .West:  return 0;
				case .North: return 270;
				case .East:  return 180;
				default:     return 0;
			}
		}
	}
}