using System;
using System.IO;
using System.Collections;
using System.Diagnostics;

namespace Meteorite{
	static class BlockModelLoader {
		private static float MIN_SCALE = 1f / Math.Cos(0.3926991f) - 1f;
		private static float MAX_SCALE = 1f / Math.Cos(0.7853981852531433f) - 1f;

		private static Dictionary<String, Json> MODEL_CACHE;

		public static void LoadModels() {
			Stopwatch sw = scope .(true);

			MODEL_CACHE = new .();
			Dictionary<String, List<(Quad, int[4])>> textures = new .();

			// Load models
			for (Block block in Registry.BLOCKS) {
				if (block == Blocks.AIR) continue;

				for (BlockState blockState in block) {
					// Read blockstate json
					String blockstatePath = scope $"assets/blockstates/{block.id}.json";

					if (!File.Exists(blockstatePath)) {
						Log.Error("Failed to find blockstate file for block with id '{}'", block.id);
						continue;
					}

					Json blockstateJson = JsonParser.ParseFile(blockstatePath);

					if (blockstateJson.Contains("multipart")) {
						List<RawModel> modelJsons = GetMultipartModels(blockState, blockstateJson);
						Model model = new .();

						for (RawModel rawModel in modelJsons) {
							for (let j in rawModel.json["elements"].AsArray) {
								ParseElement(block, textures, model, rawModel.json, j, rawModel.rotation);
							}
						}

						model.Finish();
						blockState.model = model;
						DeleteContainerAndDisposeItems!(modelJsons);
					}
					else {
						if (GetVariantModel(block, blockState, blockstateJson) case .Ok(let rawModel)) {
							Model model = new .();

							for (let j in rawModel.json["elements"].AsArray) {
								ParseElement(block, textures, model, rawModel.json, j, rawModel.rotation);
							}

							model.Finish();
							blockState.model = model;
							rawModel.Dispose();
						}
					}
				}
			}

			// Create texture atlas
			int s = 512;
			TexturePacker packer = scope .(s);

			for (let pair in textures) {
				String path = scope $"assets/textures/{pair.key}.png";
				let (x, y) = packer.Add(path);

				for (let a in pair.value) {
					a.0.region = .((float) (x + a.1[0]) / s, (float) (y + a.1[1]) / s, (float) (x + a.1[2]) / s, (float) (y + a.1[3]) / s);
				}
			}

			Blocks.ATLAS = packer.CreateTexture("Block atlas");

			DeleteDictionaryAndKeysAndValues!(textures);

			for (let pair in MODEL_CACHE) {
				delete pair.key;
				pair.value.Dispose();
			}
			delete MODEL_CACHE;

			Log.Info("Loaded block models in {:0.000} ms", sw.Elapsed.TotalMilliseconds);
		}

		private static void ParseElement(Block block, Dictionary<String, List<(Quad, int[4])>> textures, Model model, Json modelJson, Json json, Vec3f blockStateRotation) {
			// Parse from
			Json fromJson = json["from"];
			Vec3f from = .((.) fromJson[0].AsNumber / 16, (.) fromJson[1].AsNumber / 16, (.) fromJson[2].AsNumber / 16);

			// Parse to
			Json toJson = json["to"];
			Vec3f to = .((.) toJson[0].AsNumber / 16, (.) toJson[1].AsNumber / 16, (.) toJson[2].AsNumber / 16);

			for (let pair in json["faces"].AsObject) {
				// Parse cull face
				QuadCullFace cullFace = .None;

				if (pair.value.Contains("cullface")) {
					switch (pair.value["cullface"].AsString) {
					case "up": cullFace = .Top;
					case "down": cullFace = .Bottom;
					case "east": cullFace = .East;
					case "west": cullFace = .West;
					case "north": cullFace = .North;
					case "south": cullFace = .South;
					}
				}

				// Get direction. vertices and light
				Direction direction = default;
				Vec3f[4] vertices = .();
				float light = 1;

				switch (pair.key) {
				case "up":
					direction = .Up;
					vertices[0] = .(from.x, to.y, from.z);
					vertices[1] = .(to.x, to.y, from.z);
					vertices[2] = .(to.x, to.y, to.z);
					vertices[3] = .(from.x, to.y, to.z);
				case "down":
					direction = .Down;
					vertices[0] = .(from.x, from.y, from.z);
					vertices[1] = .(from.x, from.y, to.z);
					vertices[2] = .(to.x, from.y, to.z);
					vertices[3] = .(to.x, from.y, from.z);
				case "east":
					direction = .East;
					vertices[0] = .(to.x, from.y, from.z);
					vertices[1] = .(to.x, from.y, to.z);
					vertices[2] = .(to.x, to.y, to.z);
					vertices[3] = .(to.x, to.y, from.z);
				case "west":
					direction = .West;
					vertices[0] = .(from.x, from.y, from.z);
					vertices[1] = .(from.x, to.y, from.z);
					vertices[2] = .(from.x, to.y, to.z);
					vertices[3] = .(from.x, from.y, to.z);
				case "north":
					direction = .North;
					vertices[0] = .(from.x, from.y, from.z);
					vertices[1] = .(to.x, from.y, from.z);
					vertices[2] = .(to.x, to.y, from.z);
					vertices[3] = .(from.x, to.y, from.z);
				case "south":
					direction = .South;
					vertices[0] = .(from.x, from.y, to.z);
					vertices[1] = .(from.x, to.y, to.z);
					vertices[2] = .(to.x, to.y, to.z);
					vertices[3] = .(to.x, from.y, to.z);
				}

				// Get UV
				int[4] uv = .(0, 0, 16, 16);

				if (pair.value.Contains("uv")) {
					let uvJson = pair.value["uv"].AsArray;

					uv[0] = (.) uvJson[0].AsNumber;
					uv[1] = (.) uvJson[1].AsNumber;
					uv[2] = (.) uvJson[2].AsNumber;
					uv[3] = (.) uvJson[3].AsNumber;
				}

				// Block state rotation
				/*if (blockStateRotation.y != 0) {
					// Vertices
					Vec3f origin = .(0.5f, 0.5f, 0.5f);
					Mat4 m = Mat4.Identity().Translate(origin).Rotate(.(0, 1, 0), -blockStateRotation.y).Translate(-origin);
	
					for (int i < 4) {
						vertices[i] = .(m * Vec4(vertices[i], 1));
					}

					int count = (int) blockStateRotation.y / 90;
					for (int i < count) {
						//direction = Rotate(direction);

						//if (direction == .Up) Rotate(ref uv);
					}
				}*/

				// Rotation
				if (json.Contains("rotation")) {
					Json rotationJson = json["rotation"];
					Json originJson = rotationJson["origin"];

					Vec3f origin = .(
						(.) originJson.AsArray[0].AsNumber / 16,
						(.) originJson.AsArray[1].AsNumber / 16,
						(.) originJson.AsArray[2].AsNumber / 16
					);

					Vec3f axis = .();
					switch (rotationJson["axis"].AsString) {
					case "x": axis.x = 1;
					case "y": axis.y = 1;
					case "z": axis.z = 1;
					}

					float angle = (.) rotationJson["angle"].AsNumber;

					Mat4 matrix = Mat4.Identity().Translate(origin);

					if (rotationJson.Contains("rescale") && rotationJson["rescale"].AsBool) {
						float scale = Math.Abs(angle) == 22.5f ? MIN_SCALE : MAX_SCALE;
						Vec3f s;

						if (axis.x == 1) s = .(0, 1, 1);
						else if (axis.y == 1) s = .(1, 0, 1);
						else s = .(1, 1, 0);

						matrix = matrix.Scale(.(1, 1, 1) + s * scale);
					}

					matrix = matrix.Rotate(axis, angle).Translate(-origin);

					for (int i < 4) {
						vertices[i] = .(matrix * Vec4(vertices[i], 1));
					}
				}

				// Light
				switch (direction) {
				case .Down: light = 0.4f;
				case .East, .West: light = 0.6f;
				case .North, .South: light = 0.8f;
				default:
				}

				// TODO: crong
				if (block.cross) light = 1;

				// Resolve texture
				String _texture = ResolveTexture(modelJson, pair.value["texture"].AsString);
				if (_texture == null) continue;

				String texture = _texture.Contains(':') ? scope .(_texture.Substring(10)) : _texture;

				List<(Quad, int[4])> textureQuads = textures.GetValueOrDefault(texture);
				if (textureQuads == null) {
					textureQuads = new .();
					textures[new .(texture)] = textureQuads;
				}

				// Tint
				bool tint = pair.value.Contains("tintindex");

				// Create quad
				Quad quad = new .(direction, vertices, cullFace, light, tint);
				textureQuads.Add((quad, uv));

				model.Add(quad);
			}
		}

		private static Direction Rotate(Direction direction) {
			switch (direction) {
			case .South: return .West;
			case .West: return .North;
			case .North: return .East;
			case .East: return .South;
			default: return direction;
			}
		}

		private static void Rotate<T>(ref T[4] array) {
			T temp = array[0];
			array[0] = array[1];
			array[1] = array[2];
			array[2] = array[3];
			array[3] = temp;
		}

		private static String ResolveTexture(Json json, String name) {
			var name;

			while (name.StartsWith('#')) {
				String key = scope .(name.Substring(1));
				if (!json["textures"].Contains(key)) return null;

				name = json["textures"][key].AsString;
			}

			return name;
		}

		private static List<RawModel> GetMultipartModels(BlockState blockState, Json blockstateJson) {
			List<RawModel> modelJsons = new .();
			String str1 = scope .();
			String str2 = scope .();

			for (Json json in blockstateJson["multipart"].AsArray) {
				bool apply = true;

				if (json.Contains("when")) {
					for (let pair in json["when"].AsObject) {
						blockState.GetProperty(pair.key).GetValueString(str1);
						pair.value.ToString(str2);

						if (str1 != str2) {
							apply = false;
							break;
						}

						str1.Clear();
						str2.Clear();
					}
				}

				if (apply) {
					Json json2 = .Object();
					json2["parent"] = .String(json["apply"]["model"].AsString);

					Vec3f rotation = .(
						(.) json["apply"]["x"].AsNumber,
						(.) json["apply"]["y"].AsNumber,
						(.) json["apply"]["z"].AsNumber
					);

					if (GetMergedModel(json2) case .Ok(let j)) {
						modelJsons.Add(.(j, rotation));
					}
				}
			}

			blockstateJson.Dispose();
			return modelJsons;
		}

		private static Result<RawModel> GetVariantModel(Block block, BlockState blockState, Json blockstateJson) {
			// Merge models
			Json a = GetVariant(blockstateJson["variants"], blockState);
			Json variant = a;
			StringView b;

			if (a.IsObject) b = a["model"].AsString;
			else {
				variant = a[0];
				b = variant["model"].AsString;
			}

			Json json = .Object();
			json["parent"] = .String(b);

			switch (GetMergedModel(json)) {
			case .Ok(let j): json = j;
			case .Err: return .Err;
			}

			// Check rotation
			Vec3f rotation = .();

			if (variant.Contains("x")) rotation.x = (.) variant["x"].AsNumber;
			if (variant.Contains("y")) rotation.y = (.) variant["y"].AsNumber;
			if (variant.Contains("z")) rotation.z = (.) variant["z"].AsNumber;
			
			blockstateJson.Dispose();
			return RawModel(json, rotation);
		}

		private static Result<Json> GetMergedModel(Json json) {
			while (json.Contains("parent")) {
				StringView model = json["parent"].AsString;
				if (model.Contains(':')) model = model.Substring(10);
				StringView modelPath = scope $"assets/models/{model}.json";

				// Remove parent
				json.Remove("parent");

				// Check cache
				String _;
				Json cachedJson;
				if (MODEL_CACHE.TryGet(scope .(modelPath), out _, out cachedJson)) {
					json.Merge(cachedJson);
				} else {
					// Read model json
					if (!File.Exists(modelPath)) {
						Log.Error("Failed to find model file with path '{}'", modelPath);
						return .Err;
					}

					// Merge and add to cache
					Json j = JsonParser.ParseFile(modelPath);
					MODEL_CACHE[new .(modelPath)] = j;

					json.Merge(j);
				}
			}

			return json;
		}

		private static Json GetVariant(Json json, BlockState blockState) {
			List<(Json, Dictionary<StringView, StringView>)> variants = scope .(json.AsObject.Count);

			for (let pair in json.AsObject) {
				Dictionary<StringView, StringView> variant = scope:: .();
				variants.Add((pair.value, variant));

				if (pair.key.IsEmpty) continue;

				for (StringView property in pair.key.Split(',')) {
					var e = property.Split('=');
					variant[e.GetNext()] = e.GetNext();
				}
			}

			String str = scope .();

			for (var it = variants.GetEnumerator();;) {
				if (!it.MoveNext()) break;
				let variant = it.Current.1;

				for (let pair in variant) {
					let property = blockState.GetProperty(pair.key);

					str.Clear();
					property.GetValueString(str);

					if (str != pair.value) {
						it.Remove();
						break;
					}
				}
			}

			return variants[0].0;
		}

		private struct RawModel : IDisposable {
			public Json json;
			public Vec3f rotation;

			public this(Json json, Vec3f rotation) {
				this.json = json;
				this.rotation = rotation;
			}

			public void Dispose() {
				json.Dispose();
			}
		}
	}
}