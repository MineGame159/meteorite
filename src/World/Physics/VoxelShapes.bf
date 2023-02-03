using System;
using System.Collections;

using Cacti;
using Cacti.Json;

namespace Meteorite {
	static class VoxelShapes {
		public static VoxelShape BLOCK = new VoxelShape().Add(.(), .(1, 1, 1));

		private static Dictionary<String, Shapes> SHAPES;

		static ~this() {
			delete BLOCK;
			if (SHAPES == null) return;

			for (let pair in SHAPES) {
				delete pair.key;
				pair.value.Dispose();
			}
			
			delete SHAPES;
		}

		public static void Init() {
			Json json = Meteorite.INSTANCE.resources.ReadJson("data/voxel_shapes.json");
			SHAPES = new .((.) json.AsObject.Count);

			for (let pair in json.AsObject) {
				VoxelShape shape = ParseShape(pair.value["shape"]);
				VoxelShape collision = ParseShape(pair.value["collision"]);
				VoxelShape raycast = ParseShape(pair.value["raycast"]);

				SHAPES[new .(pair.key)] = .(shape, collision, raycast);
			}

			json.Dispose();
		}

		private static VoxelShape ParseShape(Json json) {
			if (json.IsString) return BLOCK;
			if (json.AsArray.IsEmpty) return null;

			VoxelShape shape = new .();

			for (let j in json.AsArray) {
				// Min
				Vec3d min = .();
				min.x = (.) j[0].AsNumber;
				min.y = (.) j[1].AsNumber;
				min.z = (.) j[2].AsNumber;

				// Max
				Vec3d max = .();
				max.x = (.) j[3].AsNumber;
				max.y = (.) j[4].AsNumber;
				max.z = (.) j[5].AsNumber;

				shape.Add(min, max);
			}

			return shape;
		}

		public static Shapes Get(BlockState blockState) {
			String s = scope .();

			s.Append(blockState.block.id);
			s.Append('[');
			for (let property in blockState.properties) {
				if (@property.Index > 0) s.Append(',');
				s.Append(property.info.name);
				s.Append(':');
				property.GetValueString(s);
			}
			s.Append(']');

			Shapes shapes;
			if (SHAPES.TryGetValue(s, out shapes)) return shapes;

			return .(BLOCK, BLOCK, null);
		}

		public struct Shapes : this(VoxelShape shape, VoxelShape collision, VoxelShape raycast) {
			public void Dispose() {
				if (shape != BLOCK) delete shape;
				if (collision != BLOCK) delete collision;
				if (raycast != BLOCK) delete raycast;
			}
		}
	}
}