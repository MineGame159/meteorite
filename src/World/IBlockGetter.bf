using System;

using Cacti;

namespace Meteorite;

interface IBlockGetter {
	public BlockState GetBlock(int x, int y, int z);

	public BlockState GetBlock(Vec3i pos) => GetBlock(pos.x, pos.y, pos.z);
}