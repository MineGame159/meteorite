using System;
using System.Collections;

using Cacti;

namespace Meteorite;

class PhysicsResult {
	public Vec3d newPosition;
	public Vec3d newVelocity;

	public bool isOnGround;
	public bool collisionX;
	public bool collisionY;
	public bool collisionZ;

	public Vec3d originalDelta;
	public Vec3d collidedBlockY;
	public Block blockTypeY;
}

class SweepResult {
	public double res;
	public double normalX, normalY, normalZ;
	public Vec3d collidedShapePosition;
	public Block blockType;
	public VoxelShape collidedShape;
	
	public this(double res, double normalX, double normalY, double normalZ, VoxelShape collidedShape) {
		this.res = res;
		this.normalX = normalX;
		this.normalY = normalY;
		this.normalZ = normalZ;
		this.collidedShape = collidedShape;
	}
}

static class BlockCollision {
	[Tracy.Profile]
	public static void HandlePhysics(AABB boundingBox, Vec3d velocity, Vec3d entityPosition, IBlockGetter getter, PhysicsResult result) {
		if (velocity.IsZero) {
			result.newPosition = entityPosition;
			result.newVelocity = velocity;
		}

		// Expensive AABB computation
		StepPhysics(boundingBox, velocity, entityPosition, getter, result);
	}

	private static void StepPhysics(AABB boundingBox, Vec3d velocity, Vec3d entityPosition, IBlockGetter getter, PhysicsResult actualResult) {
		// Allocate once and update values
		SweepResult finalResult = scope .(1 - RayUtils.EPSILON, 0, 0, 0, null);

		bool foundCollisionX = false, foundCollisionY = false, foundCollisionZ = false;
		Vec3d collisionYBlock = .ZERO;
		Block blockYType = Blocks.AIR;

		PhysicsResult result = scope .();

		ComputePhysics(boundingBox, velocity, entityPosition, getter, finalResult, result);

		// Loop until no collisions are found.
		// When collisions are found, the collision axis is set to 0
		// Looping until there are no collisions will allow the entity to move in axis other than the collision axis after a collision.
		while (result.collisionX || result.collisionY || result.collisionZ) {
			// Reset final result
			finalResult.res = 1 - RayUtils.EPSILON;
			finalResult.normalX = 0;
			finalResult.normalY = 0;
			finalResult.normalZ = 0;

			if (result.collisionX) foundCollisionX = true;
			if (result.collisionZ) foundCollisionZ = true;
			if (result.collisionY) {
				foundCollisionY = true;
				// If we are only moving in the y-axis
				if (!result.collisionX && !result.collisionZ && velocity.x == 0 && velocity.z == 0) {
					collisionYBlock = result.collidedBlockY;
					blockYType = result.blockTypeY;
				}
			}
			// If all axis have had collisions, break
			if (foundCollisionX && foundCollisionY && foundCollisionZ) break;
			// If the entity isn't moving, break
			if (result.newVelocity.IsZero) break;

			ComputePhysics(boundingBox, result.newVelocity, result.newPosition, getter, finalResult, result);
		}

		double newDeltaX = foundCollisionX ? 0 : velocity.x;
		double newDeltaY = foundCollisionY ? 0 : velocity.y;
		double newDeltaZ = foundCollisionZ ? 0 : velocity.z;

		actualResult.newPosition = result.newPosition;
		actualResult.newVelocity = .(newDeltaX, newDeltaY, newDeltaZ);
		actualResult.isOnGround = newDeltaY == 0 && velocity.y < 0;
		actualResult.collisionX = foundCollisionX;
		actualResult.collisionY = foundCollisionY;
		actualResult.collisionZ = foundCollisionZ;
		actualResult.originalDelta = velocity;
		actualResult.collidedBlockY = collisionYBlock;
		actualResult.blockTypeY = blockYType;
	}
	
	[Tracy.Profile]
	private static void ComputePhysics(AABB boundingBox, Vec3d velocity, Vec3d entityPosition, IBlockGetter getter, SweepResult finalResult, PhysicsResult result) {
		SlowPhysics(boundingBox, velocity, entityPosition, getter, finalResult);

		bool collisionX = finalResult.normalX != 0;
		bool collisionY = finalResult.normalY != 0;
		bool collisionZ = finalResult.normalZ != 0;

		double deltaX = finalResult.res * velocity.x;
		double deltaY = finalResult.res * velocity.y;
		double deltaZ = finalResult.res * velocity.z;

		if (Math.Abs(deltaX) < RayUtils.EPSILON) deltaX = 0;
		if (Math.Abs(deltaY) < RayUtils.EPSILON) deltaY = 0;
		if (Math.Abs(deltaZ) < RayUtils.EPSILON) deltaZ = 0;

		Vec3d finalPos = entityPosition + .(deltaX, deltaY, deltaZ);

		double remainingX = collisionX ? 0 : velocity.x - deltaX;
		double remainingY = collisionY ? 0 : velocity.y - deltaY;
		double remainingZ = collisionZ ? 0 : velocity.z - deltaZ;

		result.newPosition = finalPos;
		result.newVelocity = .(remainingX, remainingY, remainingZ);
		result.isOnGround = collisionY;
		result.collisionX = collisionX;
		result.collisionY = collisionY;
		result.collisionZ = collisionZ;
		result.originalDelta = .ZERO;
		result.collidedBlockY = finalResult.collidedShapePosition;
		result.blockTypeY = finalResult.blockType;
	}
	
	[Tracy.Profile]
	private static void SlowPhysics(AABB boundingBox, Vec3d velocity, Vec3d entityPosition, IBlockGetter getter, SweepResult finalResult) {
		Vec3d min = boundingBox.min + entityPosition - boundingBox.Width / 2;
		Vec3d max = boundingBox.max + entityPosition - boundingBox.Width / 2;

		min = min.Min(min + velocity);
		max = max.Max(max + velocity);

		Vec3i start = (.) min - 1;
		Vec3i end = (.) max + 1;

		for (int x = start.x; x <= end.x; x++) {
			for (int y = start.y; y <= end.y; y++) {
				for (int z = start.z; z <= end.z; z++) {
					CheckBoundingBox(x, y, z, velocity, entityPosition, boundingBox, getter, finalResult);
				}
			}
		}
	}

	private static bool CheckBoundingBox(int blockX, int blockY, int blockZ, Vec3d entityVelocity, Vec3d entityPosition, AABB boundingBox, IBlockGetter getter, SweepResult finalResult) {
		// Don't step if chunk isn't loaded yet
		BlockState currentBlock = getter.GetBlock(blockX, blockY, blockZ);
		VoxelShape currentShape = currentBlock.CollisionShape;

		if (currentShape == null) return false;

		bool currentCollidable = !currentShape.GetBoundingBox().max.IsZero;
		bool currentShort = currentShape.GetBoundingBox().max.y < 0.5;

		// only consider the block below if our current shape is sufficiently short
		if (currentShort && ShouldCheckLower(entityVelocity, entityPosition, blockX, blockY, blockZ)) {
			// we need to check below for a tall block (fence, wall, ...)
			Vec3d belowPos = .(blockX, blockY - 1, blockZ);
			BlockState belowBlock = getter.GetBlock(blockX, blockY - 1, blockZ);
			VoxelShape belowShape = belowBlock.CollisionShape;

			Vec3d currentPos = .(blockX, blockY, blockZ);
			// don't fall out of if statement, we could end up redundantly grabbing a block, and we only need to
			// collision check against the current shape since the below shape isn't tall
			if (belowShape != null && belowShape.GetBoundingBox().max.y > 1) {
				// we should always check both shapes, so no short-circuit here, to handle cases where the bounding box
				// hits the current solid but misses the tall solid
				return belowShape.IntersectBoxSwept(entityPosition, entityVelocity, belowPos, boundingBox, finalResult) | (currentCollidable && currentShape.IntersectBoxSwept(entityPosition, entityVelocity, currentPos, boundingBox, finalResult));
			} else {
				return currentCollidable && currentShape.IntersectBoxSwept(entityPosition, entityVelocity, currentPos, boundingBox, finalResult);
			}
		}

		if (currentCollidable && currentShape.IntersectBoxSwept(entityPosition, entityVelocity, .(blockX, blockY, blockZ), boundingBox, finalResult)) {
			// if the current collision is sufficiently short, we might need to collide against the block below too
			if (currentShort) {
				Vec3d belowPos = .(blockX, blockY - 1, blockZ);
				BlockState belowBlock = getter.GetBlock(blockX, blockY - 1, blockZ);
				VoxelShape belowShape = belowBlock.CollisionShape;
				// only do sweep if the below block is big enough to possibly hit
				if (belowShape != null && belowShape.GetBoundingBox().max.y > 1) belowShape.IntersectBoxSwept(entityPosition, entityVelocity, belowPos, boundingBox, finalResult);
			}
			return true;
		}
		return false;
	}

	private static bool ShouldCheckLower(Vec3d entityVelocity, Vec3d entityPosition, int blockX, int blockY, int blockZ) {
		double yVelocity = entityVelocity.y;
		// if moving horizontally, just check if the floor of the entity's position is the same as the blockY
		if (yVelocity == 0) return Math.Floor(entityPosition.y) == blockY;
		double xVelocity = entityVelocity.x;
		double zVelocity = entityVelocity.z;
		// if moving straight up, don't bother checking for tall solids beneath anything
		// if moving straight down, only check for a tall solid underneath the last block
		if (xVelocity == 0 && zVelocity == 0)
			return yVelocity < 0 && blockY == Math.Floor(entityPosition.y + yVelocity);
		// default to true: if no x velocity, only consider YZ line, and vice-versa
		bool underYX = xVelocity != 0 && ComputeHeight(yVelocity, xVelocity, entityPosition.y, entityPosition.x, blockX) >= blockY;
		bool underYZ = zVelocity != 0 && ComputeHeight(yVelocity, zVelocity, entityPosition.y, entityPosition.z, blockZ) >= blockY;
		// true if the block is at or below the same height as a line drawn from the entity's position to its final
		// destination
		return underYX && underYZ;
	}

	/*
	computes the height of the entity at the given block position along a projection of the line it's travelling along
	(YX or YZ). the returned value will be greater than or equal to the block height if the block is along the lower
	layer of intersections with this line.
	 */
	private static double ComputeHeight(double yVelocity, double velocity, double entityY, double pos, int blockPos) {
		double m = yVelocity / velocity;
		/*
		offsetting by 1 is necessary with a positive slope, because we can clip the bottom-right corner of blocks
		without clipping the "bottom-left" (the smallest corner of the block on the YZ or YX plane). without the offset
		these would not be considered to be on the lowest layer, since our block position represents the bottom-left
		corner
		 */
		return m * (blockPos - pos + (m > 0 ? 1 : 0)) + entityY;
	}
}