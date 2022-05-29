using System;

namespace Meteorite {
	class AirBlock : Block {
		public this(StringView id, BlockSettings settings) : base(id, settings) {}

		public override VoxelShape GetShape() => .EMPTY;
	}
}