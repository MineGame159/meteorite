using System;

using Cacti;
using Cacti.Graphics;

namespace Cacti;

extension Buffers {
	public static GpuBuffer QUAD_INDICES;

	public static void Destroy() {
		ReleaseAndNullify!(QUAD_INDICES);
	}
	
	[Tracy.Profile]
	public static void CreateGlobalIndices() {
		const int count = 8192 * 32;
		uint32* buffer = new uint32[6 * count]*;
		uint32 v = 0;

		for (int i < count) {
			uint32 i1 = v++;
			uint32 i2 = v++;
			uint32 i3 = v++;
			uint32 i4 = v++;

			buffer[i * 6] = i1;
			buffer[i * 6 + 1] = i2;
			buffer[i * 6 + 2] = i3;

			buffer[i * 6 + 3] = i3;
			buffer[i * 6 + 4] = i4;
			buffer[i * 6 + 5] = i1;
		}

		QUAD_INDICES = Gfx.Buffers.Create("Quads", .Index, .Mappable, 6 * count * 4);
		QUAD_INDICES.Upload(buffer, QUAD_INDICES.Size);

		delete buffer;
	}
}