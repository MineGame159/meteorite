using System;
using System.Collections;
using System.Diagnostics;

namespace Meteorite{
	static class BlockModelLoader {
		private static float MIN_SCALE = 1f / Math.Cos(0.3926991f) - 1f;
		private static float MAX_SCALE = 1f / Math.Cos(0.7853981852531433f) - 1f;

		private static Dictionary<String, Json> MODEL_CACHE;

		public static void LoadModels() {
			Stopwatch sw = scope .(true);
			//let omg = Profiler.StartSampling();

			MODEL_CACHE = new .();
			Dictionary<String, List<Quad>> textures = new .();

			// Load models
			for (Block block in Registry.BLOCKS) {
				// Read blockstate json
				Json? blockstateJson = GetMergedBlockstateJson(block);

				if (blockstateJson == null) {
					Log.Error("Failed to find blockstate file for block with id '{}'", block.id);
				}

				// Loop all block states
				for (BlockState blockState in block) {
					Model model = new .();

					if (blockstateJson != null) {
						if (blockstateJson.Value.Contains("multipart")) {
							List<RawModel> modelJsons = GetMultipartModels(blockState, blockstateJson.Value);
	
							for (RawModel rawModel in modelJsons) {
								for (let j in rawModel.json["elements"].AsArray) {
									ParseElement(block, textures, model, rawModel.json, j, rawModel.rotation, rawModel.uvlock);
								}
							}
	
							DeleteContainerAndDisposeItems!(modelJsons);
						}
						else {
							if (GetVariantModel(block, blockState, blockstateJson.Value) case .Ok(let rawModel)) {
								if (rawModel.json.Contains("elements")) {
									for (let j in rawModel.json["elements"].AsArray) {
										ParseElement(block, textures, model, rawModel.json, j, rawModel.rotation, rawModel.uvlock);
									}
								}
	
								rawModel.Dispose();
							}
						}
					}

					model.Finish();
					blockState.model = model;
				}

				blockstateJson.Value.Dispose();
			}

			// Create texture atlas
			TextureManager t = Meteorite.INSTANCE.textures;

			for (let pair in textures) {
				let texture = t.Add(scope $"{pair.key}.png");

				for (let a in pair.value) {
					a.texture = texture;
				}
			}

			t.Finish();
			DeleteDictionaryAndKeysAndValues!(textures);

			for (let pair in MODEL_CACHE) {
				delete pair.key;
				pair.value.Dispose();
			}
			delete MODEL_CACHE;

			//omg.Dispose();
			Log.Info("Loaded block models in {:0.000} ms", sw.Elapsed.TotalMilliseconds);
		}

		private static Json? GetMergedBlockstateJson(Block block) {
			String path = scope $"blockstates/{block.id}.json";
			Json? json = null;

			Meteorite.INSTANCE.resources.ReadJsons(path, scope [&](j) => {
				if (json == null) {
					json = j;
					return;
				}

				if (json.Value.Contains("variants") && j.Contains("variants")) {
					Json variants1 = json.Value["variants"];
					Json variants2 = j["variants"];

					for (let pair in variants2.AsObject) {
						if (variants1.Contains(pair.key)) variants1.Remove(pair.key);

						Json a = pair.value.IsArray ? .Array() : .Object();
						a.Merge(pair.value);
						variants1[pair.key] = a;
					}
				}

				j.Dispose();
			});

			return json;
		}

		private static void ParseElement(Block block, Dictionary<String, List<Quad>> textures, Model model, Json modelJson, Json json, Vec3f blockStateRotation, bool uvlock) {
			// Parse from
			Json fromJson = json["from"];
			Vec3f fromF = .((.) fromJson[0].AsNumber, (.) fromJson[1].AsNumber, (.) fromJson[2].AsNumber);
			Vec3f from = fromF / 16;

			// Parse to
			Json toJson = json["to"];
			Vec3f toF = .((.) toJson[0].AsNumber, (.) toJson[1].AsNumber, (.) toJson[2].AsNumber);
			Vec3f to = toF / 16;

			for (let pair in json["faces"].AsObject) {
				// Get direction. vertices and light
				Direction direction = default;
				Vec3f[4] positions = .();
				Vec2f[4] uvs = .();
				float light = 1;

				switch (pair.key) {
				case "up":
					direction = .Up;
					positions[0] = .(from.x, to.y, from.z);
					positions[1] = .(to.x, to.y, from.z);
					positions[2] = .(to.x, to.y, to.z);
					positions[3] = .(from.x, to.y, to.z);
				case "down":
					direction = .Down;
					positions[0] = .(from.x, from.y, from.z);
					positions[1] = .(from.x, from.y, to.z);
					positions[2] = .(to.x, from.y, to.z);
					positions[3] = .(to.x, from.y, from.z);
				case "east":
					direction = .East;
					positions[0] = .(to.x, from.y, from.z);
					positions[1] = .(to.x, from.y, to.z);
					positions[2] = .(to.x, to.y, to.z);
					positions[3] = .(to.x, to.y, from.z);
				case "west":
					direction = .West;
					positions[0] = .(from.x, from.y, from.z);
					positions[1] = .(from.x, to.y, from.z);
					positions[2] = .(from.x, to.y, to.z);
					positions[3] = .(from.x, from.y, to.z);
				case "north":
					direction = .North;
					positions[0] = .(from.x, from.y, from.z);
					positions[1] = .(to.x, from.y, from.z);
					positions[2] = .(to.x, to.y, from.z);
					positions[3] = .(from.x, to.y, from.z);
				case "south":
					direction = .South;
					positions[0] = .(from.x, from.y, to.z);
					positions[1] = .(from.x, to.y, to.z);
					positions[2] = .(to.x, to.y, to.z);
					positions[3] = .(to.x, from.y, to.z);
				}

				Direction finalDirection = direction;

				// Get UV
				float[4] uv = ?;

				if (pair.value.Contains("uv")) {
					let uvJson = pair.value["uv"].AsArray;

					uv[0] = (.) uvJson[0].AsNumber;
					uv[1] = (.) uvJson[1].AsNumber;
					uv[2] = (.) uvJson[2].AsNumber;
					uv[3] = (.) uvJson[3].AsNumber;
				}
				else {
					switch (direction) {
					case .North, .South:
						uv[0] = fromF.x;
						uv[2] = toF.x;
						uv[1] = 16 - toF.y;
						uv[3] = 16 - fromF.y;
					case .West, .East:
						uv[0] = fromF.z;
						uv[2] = toF.z;
						uv[1] = 16 - toF.y;
						uv[3] = 16 - fromF.y;
					case .Down, .Up:
						uv[0] = fromF.x;
						uv[2] = toF.x;
						uv[1] = 16 - toF.z;
						uv[3] = 16 - fromF.z;
					}
				}

				// Rotate direction
				if (blockStateRotation.x > 0) {
					int o = (.) blockStateRotation.x/ 90;
					finalDirection = RotateDirection(finalDirection, o, FACE_ROTATION_X, scope .(.East, .West));
				}

				if (blockStateRotation.y > 0) {
					int o = (.) blockStateRotation.y / 90;
					finalDirection = RotateDirection(finalDirection, o, FACE_ROTATION, scope .(.Up, .Down));
				}

				let tw = 16;
				let th = 16;

				// UV Rotation
				if (pair.value.Contains("rotation")) {
					int rotation = (.) pair.value["rotation"].AsNumber;

					let ox1 = uv[0];
					let ox2 = uv[2];
					let oy1 = uv[1];
					let oy2 = uv[3];

					switch (rotation) {
						case 270:
						    uv[1] = tw - ox2;
						    uv[3] = tw - ox1;
						    uv[0] = oy1;
						    uv[2] = oy2;
						case 180:
						    uv[1] = th - oy2;
						    uv[3] = th - oy1;
						    uv[0] = tw - ox2;
						    uv[2] = tw - ox1;
						case 90:
						    uv[1] = ox1;
						    uv[3] = ox2;
						    uv[0] = th - oy2;
						    uv[2] = th - oy1;
					}
				}

				switch (direction) {
				case .Up:
					uvs[0] = .(uv[0], uv[1]);
					uvs[1] = .(uv[2], uv[1]);
					uvs[2] = .(uv[2], uv[3]);
					uvs[3] = .(uv[0], uv[3]);
				case .Down, .South, .West:
					uvs[0] = .(uv[0], uv[3]);
					uvs[1] = .(uv[0], uv[1]);
					uvs[2] = .(uv[2], uv[1]);
					uvs[3] = .(uv[2], uv[3]);
				case .North, .East:
					uvs[0] = .(uv[2], uv[3]);
					uvs[1] = .(uv[0], uv[3]);
					uvs[2] = .(uv[0], uv[1]);
					uvs[3] = .(uv[2], uv[1]);
				}

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
						positions[i] = .(matrix * Vec4(positions[i], 1));
					}
				}

				// Block state rotation
				if (blockStateRotation.x > 0) {
					let rot_x = blockStateRotation.x * (Math.PI_f / 180f);
					let c = Math.Cos(rot_x);
					let s = Math.Sin(rot_x);

					for (var v in ref positions) {
						let z = v.z - 0.5f;
						let y = v.y - 0.5f;
						v.z = 0.5f + (z * c - y * s);
						v.y = 0.5f + (y * c + z * s);
					}
				}

				if (blockStateRotation.y > 0) {
				    let rot_y = blockStateRotation.y * (Math.PI_f / 180f);
					let c = Math.Cos(rot_y);
					let s = Math.Sin(rot_y);

					for (var v in ref positions) {
						let x = v.x - 0.5f;
						let z = v.z - 0.5f;
						v.x = 0.5f + (x * c - z * s);
						v.z = 0.5f + (z * c + x * s);
					}
				}

				// Rotation
				if (pair.value.Contains("rotation")) {
					Vec3f origin = .(8, 8, 0);
					Mat4 matrix = Mat4.Identity().Translate(origin).Rotate(.(0, 0, 1), (.) -pair.value["rotation"].AsNumber).Translate(-origin);

					for (int i < 4) {
						let a = matrix * Vec4(uvs[i].x, uvs[i].y, 0, 1);
						uvs[i] = .(a.x, a.y);
					}
				}

				// UV lock
				if (uvlock && blockStateRotation.y > 0.0 && (finalDirection == .Up || finalDirection == .Down)) {
					Vec3f origin = .(8, 0, 8);
					Mat4 matrix = Mat4.Identity().Translate(origin).Rotate(.(0, 1, 0), -blockStateRotation.y).Translate(-origin);

					for (int i < 4) {
						let a = matrix * Vec4(uvs[i].x, 0, uvs[i].y, 1);
						uvs[i] = .(a.x, a.z);
					}
				}

				if (uvlock && blockStateRotation.x > 0.0 && (finalDirection != .Up && finalDirection != .Down)) {
				    Vec3f origin = .(0, 8, 8);
					Mat4 matrix = Mat4.Identity().Translate(origin).Rotate(.(1, 0, 0), -blockStateRotation.x).Translate(-origin);

					for (int i < 4) {
						let a = matrix * Vec4(0, uvs[i].x, uvs[i].y, 1);
						uvs[i] = .(a.y, a.z);
					}
				}

				// Light
				switch (finalDirection) {
				case .Down: light = 0.4f;
				case .East, .West: light = 0.6f;
				case .North, .South: light = 0.8f;
				default:
				}

				if (!json.GetBool("shade", true)) light = 1;

				// Resolve texture
				String _texture = ResolveTexture(modelJson, pair.value["texture"].AsString);
				if (_texture == null) continue;

				String texture = _texture.Contains(':') ? scope .(_texture.Substring(10)) : _texture;

				List<Quad> textureQuads = textures.GetValueOrDefault(texture);
				if (textureQuads == null) {
					textureQuads = new .();
					textures[new .(texture)] = textureQuads;
				}

				// Tint
				bool tint = pair.value.Contains("tintindex");

				// Round vertices and uvs
				// Hopefully this doesn't break anything 2.0
				if (fromF.x >= 0 && fromF.y >= 0 && fromF.z >= 0 && toF.x <= 16 && toF.y <= 16 && toF.z <= 16) {
					for (var v in ref positions) {
						if (v.x < 0.0001) v.x = 0;
						else if (v.x > 0.9999) v.x = 1;
	
						if (v.y < 0.0001) v.y = 0;
						else if (v.y > 0.9999) v.y = 1;
	
						if (v.z < 0.0001) v.z = 0;
						else if (v.z > 0.9999) v.z = 1;
					}
				}

				for (var v in ref uvs) {
					if (v.x < 0.0001) v.x = 0;
					else if (v.x > 15.9999) v.x = 16;

					if (v.y < 0.0001) v.y = 0;
					else if (v.y > 15.9999) v.y = 16;
				}

				// Create quad
				mixin ToVertexUv(float u, float v) {
					Vec2<uint16>((.) (u / 16f * uint16.MaxValue), (.) (v / 16f * uint16.MaxValue))
				}

				Quad quad = new .(
					finalDirection,
					.(
						.(positions[0], ToVertexUv!(uvs[0].x, uvs[0].y)),
						.(positions[1], ToVertexUv!(uvs[1].x, uvs[1].y)),
						.(positions[2], ToVertexUv!(uvs[2].x, uvs[2].y)),
						.(positions[3], ToVertexUv!(uvs[3].x, uvs[3].y))
					),
					light,
					tint
				);
				
				textureQuads.Add(quad);
				model.Add(quad);
			}
		}

		private static Direction[] FACE_ROTATION = new .(.North, .East, .South, .West) ~ delete _;
		private static Direction[] FACE_ROTATION_X = new .(.North, .Down, .South, .Up) ~ delete _;

		private static Direction RotateDirection(Direction val, int offset, Direction[] rots, Direction[] invalid) {
		    for (let d in invalid) {
		        if (d == val) return val;
		    }

			int pos = 0;
			for (int i < rots.Count) {
				if (rots[i] == val) {
					pos = i;
					break;
				}
			}

			return rots[(rots.Count + pos + offset) % rots.Count];
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
					EvaluateWhen(json["when"], blockState, str1, str2, ref apply);
				}

				if (apply) {
					Json a = json["apply"];
					String b;

					if (a.IsObject) b = a["model"].AsString;
					else b = a[0]["model"].AsString;

					Json json2 = .Object();
					json2["parent"] = .String(b);

					Vec3f rotation = .(
						a.GetInt("x", 0),
						a.GetInt("y", 0),
						a.GetInt("z", 0)
					);

					if (GetMergedModel(json2) case .Ok(let j)) {
						modelJsons.Add(.(j, rotation, a.GetBool("uvlock")));
					}
				}
			}

			return modelJsons;
		}

		private static void EvaluateWhen(Json json, BlockState blockState, String str1, String str2, ref bool apply) {
			for (let pair in json.AsObject) {
				defer {
					str1.Clear();
					str2.Clear();
				}

				if (pair.key == "OR") {
					bool a = false;

					for (let j in pair.value.AsArray) {
						bool b = true;
						EvaluateWhen(j, blockState, str1, str2, ref b);

						if (b) {
							a = true;
							break;
						}
					}

					if (!a) {
						apply = false;
						break;
					}

					continue;
				}

				blockState.GetProperty(pair.key).GetValueString(str1);
				pair.value.ToString(str2);

				if (str2.Contains('|')) {
					bool a = false;

					for (let value in str2.Split('|')) {
						if (str1 == value) a = true;
					}

					if (!a) {
						apply = false;
						break;
					}
				}
				else {
					if (str1 != str2) {
						apply = false;
						break;
					}
				}
			}
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
			
			return RawModel(json, rotation, variant.GetBool("uvlock"));
		}

		private static Result<Json> GetMergedModel(Json json) {
			void Merge(Json json, Json j) {
				if (j.Contains("elements") && json.Contains("elements")) json.Merge(j, scope (key) => key != "elements");
				else json.Merge(j);
			}

			while (json.Contains("parent")) {
				StringView model = json["parent"].AsString;
				if (model.Contains(':')) model = model.Substring(10);
				StringView modelPath = scope $"models/{model}.json";

				// Remove parent
				json.Remove("parent");

				// Check cache
				String _;
				Json cachedJson;
				if (MODEL_CACHE.TryGet(scope .(modelPath), out _, out cachedJson)) {
					Merge(json, cachedJson);
				} else {
					// Merge and add to cache
					Result<Json> j = Meteorite.INSTANCE.resources.ReadJson(modelPath);

					if (j == .Err) {
						Log.Error("Failed to find model file with path '{}'", modelPath);
						return .Err;
					}

					MODEL_CACHE[new .(modelPath)] = j;
					Merge(json, j);
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

			if (variants.Count > 2) Log.Warning("More than 2 variants left");

			return variants[variants.Count - 1].0;
		}

		private struct RawModel : IDisposable {
			public Json json;
			public Vec3f rotation;
			public bool uvlock;

			public this(Json json, Vec3f rotation, bool uvlock) {
				this.json = json;
				this.rotation = rotation;
				this.uvlock = uvlock;
			}

			public void Dispose() {
				json.Dispose();
			}
		}
	}
}