using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class NamedMeshBuilderProvider {
		private Dictionary<String, MeshBuilder> meshes = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public MeshBuilder Get(String name) {
			String outKey;
			MeshBuilder outMb;
			if (meshes.TryGet(name, out outKey, out outMb)) return outMb;

			MeshBuilder mb = new .(false);

			meshes[new .(name)] = mb;
			return mb;
		}

		public Dictionary<String, MeshBuilder>.Enumerator Meshes => meshes.GetEnumerator();

		public void End() {
			for (let pair in meshes) {
				delete pair.key;
				delete pair.value;
			}

			meshes.Clear();
		}
	}
}