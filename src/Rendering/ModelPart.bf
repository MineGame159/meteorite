using System;
using System.Collections;

using Cacti;

namespace Meteorite {
	class ModelPart {
		public bool visible = true;
		public Vec3f pos, rot;

		private Cube[] cubes ~ DeleteContainerAndItems!(_);
		private Dictionary<String, ModelPart> children ~ DeleteDictionaryAndKeysAndValues!(_);

		public ModelPart GetChild(String name) => children[name];

		private mixin Vertex(MeshBuilder mb, MatrixStack matrices, Face face, Vec4f normal, int vertexI) {
			Vertex vertex = face.vertices[vertexI];
			Vec4f pos = matrices.Back * Vec4f(vertex.pos / 16, 1);

			mb.Vertex<EntityVertex>(.(
				.(pos.x, pos.y, pos.z),
				.((.) normal.x, (.) normal.y, (.) normal.z, 0),
				vertex.uv,
				.WHITE
			))
		}

		public void Render(MatrixStack matrices, MeshBuilder mb) {
			if (!visible || (cubes.IsEmpty && children.IsEmpty)) return;

			matrices.Push();
			Apply(matrices);

			for (Cube cube in cubes) {
				for (let face in cube.faces) {
					Vec4f normal = matrices.BackNormal * Vec4f(face.normal, 1) * 127;

					mb.Quad(
						Vertex!(mb, matrices, face, normal, 0),
						Vertex!(mb, matrices, face, normal, 3),
						Vertex!(mb, matrices, face, normal, 2),
						Vertex!(mb, matrices, face, normal, 1)
					);
				}
			}

			for (ModelPart child in children.Values) child.Render(matrices, mb);

			matrices.Pop();
		}

		public void Apply(MatrixStack matrices) {
			matrices.Translate(pos / 16);

			if (rot.z != 0) matrices.Rotate(.(0, 0, 1), rot.z);
			if (rot.y != 0) matrices.Rotate(.(0, 1, 0), rot.y);
			if (rot.x != 0) matrices.Rotate(.(1, 0, 0), rot.x);
		}

		public class Cube {
			public Face[6] faces;
		}

		public struct Face {
			public Vec3f normal;
			public Vertex[4] vertices;
		}

		public struct Vertex {
			public Vec3f pos;
			public Vec2<uint16> uv;
		}

		public static ModelPart Parse(Json json) {
			ModelPart part = new .();

			// Position
			Json pos = json["position"];
			part.pos = .((.) pos[0].AsNumber, (.) pos[1].AsNumber, (.) pos[2].AsNumber);

			// Rotation
			Json rot = json["rotation"];
			part.rot = .((.) rot[0].AsNumber, (.) rot[1].AsNumber, (.) rot[2].AsNumber);

			// Cubes
			Json cubes = json["cubes"];
			part.cubes = new .[cubes.AsArray.Count];

			for (let j in cubes.AsArray) {
				Cube cube = new .();
				part.cubes[@j.Index] = cube;

				// Faces
				for (let j2 in j.AsArray) {
					ref ModelPart.Face face = ref cube.faces[@j2.Index];

					// Normal
					Json normal = j2["normal"];
					face.normal.x = (.) normal[0].AsNumber;
					face.normal.y = (.) normal[1].AsNumber;
					face.normal.z = (.) normal[2].AsNumber;

					// Vertices
					for (let j3 in j2["vertices"].AsArray) {
						ref ModelPart.Vertex vertex = ref face.vertices[@j3.Index];

						// Pos
						vertex.pos.x = (.) j3[0].AsNumber;
						vertex.pos.y = (.) j3[1].AsNumber;
						vertex.pos.z = (.) j3[2].AsNumber;

						// UV
						vertex.uv.x = (.) (j3[3].AsNumber * uint16.MaxValue);
						vertex.uv.y = (.) (j3[4].AsNumber * uint16.MaxValue);
					}
				}
			}

			// Children
			Json children = json["children"];
			part.children = new .((.) children.AsObject.Count);

			for (let pair in children.AsObject) {
				ModelPart child = Parse(pair.value);
				part.children[new .(pair.key)] = child;
			}

			return part;
		}
	}
}