using System;
using System.Collections;

namespace Meteorite {
	class NamedMeshProvider {
		private List<Mesh> unusedMeshes = new .() ~ DeleteContainerAndItems!(_);
		private Dictionary<String, Mesh> meshes = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public Mesh Get(String name) {
			String outKey;
			Mesh outMesh;
			if (meshes.TryGet(name, out outKey, out outMesh)) return outMesh;

			Mesh mesh = unusedMeshes.IsEmpty ? new .(Buffers.QUAD_INDICES) : unusedMeshes.PopBack();
			mesh.Begin();

			meshes[new .(name)] = mesh;
			return mesh;
		}

		public Dictionary<String, Mesh>.Enumerator Meshes => meshes.GetEnumerator();

		public void End() {
			for (let pair in meshes) {
				delete pair.key;
				unusedMeshes.Add(pair.value);
			}

			meshes.Clear();
		}
	}
}