using System;
using System.Collections;

namespace Meteorite {
	class NamedMeshBuilderProvider {
		private Dictionary<String, MeshBuilder> meshes = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public MeshBuilder Get(String name) {
			String outKey;
			MeshBuilder outMb;
			if (meshes.TryGet(name, out outKey, out outMb)) return outMb;

			MeshBuilder mb = Meteorite.INSTANCE.frameBuffers.AllocateImmediate(.Null, Buffers.QUAD_INDICES);

			meshes[new .(name)] = mb;
			return mb;
		}

		public Dictionary<String, MeshBuilder>.Enumerator Meshes => meshes.GetEnumerator();

		public void End() {
			for (let pair in meshes) {
				delete pair.key;
			}

			meshes.Clear();
		}
	}
}