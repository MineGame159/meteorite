using System;

using Cacti;
using Cacti.Graphics;

namespace Meteorite {
	class ChestBlockEntityRenderer : BlockEntityRenderer {
		private ModelPart single ~ delete _, bottom, lid, lock;
		private ModelPart left ~ delete _, leftBottom, leftLid, leftLock;
		private ModelPart right ~ delete _, rightBottom, rightLid, rightLock;

		public this() {
			// Single
			single = Load("chest");
			bottom = single.GetChild("bottom");
			lid = single.GetChild("lid");
			lock = single.GetChild("lock");

			// Double left
			left = Load("double_chest_left");
			leftBottom = left.GetChild("bottom");
			leftLid = left.GetChild("lid");
			leftLock = left.GetChild("lock");

			// Double right
			right = Load("double_chest_right");
			rightBottom = right.GetChild("bottom");
			rightLid = right.GetChild("lid");
			rightLock = right.GetChild("lock");
		}

		public override void Render(MatrixStack matrices, BlockState blockState, BlockEntity _, NamedMeshBuilderProvider provider, float tickDelta) {
			Type type = blockState.block == Blocks.ENDER_CHEST ? .Single : (.) blockState.GetProperty("type").value;
			Direction facing = GetDirection(blockState.GetProperty("facing").value);

			matrices.Push();
			matrices.Translate(.(0.5f, 0.5f, 0.5f));
			matrices.Rotate(.(0, 1, 0), -facing.YRot);
			matrices.Translate(.(-0.5f, -0.5f, -0.5f));

			float lidAngle = 0;

			StringView material;
			switch (blockState.block) {
			case Blocks.TRAPPED_CHEST: material = "trapped";
			case Blocks.ENDER_CHEST: material = "ender";
			default: material = "normal";
			}

			if (type == .Single) {
				Render(matrices, provider.Get(scope $"entity/chest/{material}.png"), blockState, _, bottom, lid, lock, lidAngle);
			}
			else {
				if (type == .Left) Render(matrices, provider.Get(scope $"entity/chest/{material}_left.png"), blockState, _, leftBottom, leftLid, leftLock, lidAngle);
				else Render(matrices, provider.Get(scope $"entity/chest/{material}_right.png"), blockState, _, rightBottom, rightLid, rightLock, lidAngle);
			}

			matrices.Pop();
		}

		private void Render(MatrixStack matrices, MeshBuilder mb, BlockState blockState, BlockEntity blockEntity, ModelPart bottom, ModelPart lid, ModelPart lock, float lidAngle) {
			lid.rot.x = -(lidAngle * (Math.PI_f / 2f));
			lock.rot.x = lid.rot.x;

			uint32 lightUv = GetLightUv(blockState, blockEntity);

			bottom.Render(matrices, mb, lightUv);
			lid.Render(matrices, mb, lightUv);
			lock.Render(matrices, mb, lightUv);
		}

		private Direction GetDirection(int i) {
			switch (i) {
			case 0:  return .North;
			case 1:  return .South;
			case 2:  return .West;
			case 3:  return .East;
			default: return .Up;
			}
		}

		private enum Type {
			Single,
			Left,
			Right
		}
	}
}