using System;
using System.Collections;

namespace Meteorite {
	enum JsonType {
		Null,
		Object,
		Array,
		String,
		Number,
		Bool
	}

	[Union]
	struct JsonData {
		public Dictionary<String, Json> object;
		public List<Json> array;
		public String string;
		public double number;
		public bool bool;
	}

	struct Json : IDisposable {
		public JsonType type;
		private JsonData data;

		private this(JsonType type, JsonData data) {
			this.type = type;
			this.data = data;
		}

		public static Json Object() {
			JsonData data;
			data.object = new .();

			return .(.Object, data);
		}

		public static Json Array() {
			JsonData data;
			data.array = new .();

			return .(.Array, data);
		}

		public static Json String(StringView str) {
			JsonData data;
			data.string = new .(str);

			return .(.String, data);
		}

		public static Json Number(double num) {
			JsonData data;
			data.number = num;

			return .(.Number, data);
		}

		public static Json Bool(bool bool) {
			JsonData data;
			data.bool = bool;

			return .(.Bool, data);
		}

		public bool IsNull => type == .Null;
		public bool IsObject => type == .Object;
		public bool IsArray => type == .Array;
		public bool IsString => type == .String;
		public bool IsNumber => type == .Number;
		public bool IsBool => type == .Bool;

		public Dictionary<String, Json> AsObject => data.object;
		public List<Json> AsArray => data.array;
		public String AsString => data.string;
		public double AsNumber => data.number;
		public bool AsBool => data.bool;

		public Json this[String key] {
			get => AsObject.GetValueOrDefault(key);
			set { Remove(key); AsObject[new .(key)] = value; }
		}

		public Json this[int key] {
			get => AsArray[key];
		}

		public void Add(Json json) {
			AsArray.Add(json);
		}

		public bool Contains(String key) => !this[key].IsNull;

		public void Remove(String key) {
			if (AsObject.GetAndRemove(key) case .Ok(let pair)) {
				delete pair.key;
				pair.value.Dispose();
			}
		}

		public void Merge(Json json) {
			if (IsObject) {
				for (let pair in json.AsObject) {
					switch (pair.value.type) {
					case .Object:
						Json a = this[pair.key];
						if (!a.IsObject) {
							a = .Object();
							this[pair.key] = a;
						}
	
						a.Merge(pair.value);
					case .Array:
						Json a = this[pair.key];
						if (!a.IsArray) {
							a = .Array();
							this[pair.key] = a;
						}
	
						a.Merge(pair.value);
					case .String: this[pair.key] = .String(pair.value.AsString);
					case .Number, .Bool: this[pair.key] = pair.value;
					default:
					}
				}
			}
			else if (IsArray) {
				for (let j in json.AsArray) {
					switch (j.type) {
					case .Object:
						Json a = .Object();
						Add(a);

						a.Merge(j);
					case .Array:
						Json a = .Array();
						Add(a);

						a.Merge(j);
					case .String: Add(.String(j.AsString));
					case .Number, .Bool: Add(j);
					default:
					}
				}
			}
		}
		
		public void Dispose() {
			if (IsObject) {
				for (let pair in AsObject) {
					delete pair.key;
					pair.value.Dispose();
				}

				delete AsObject;
			}
			else if (IsArray) {
				DeleteContainerAndDisposeItems!(AsArray);
			}
			else if (IsString) {
				delete AsString;
			}
		}

		public override void ToString(String str) {
			switch (type) {
			case .String: str.Append(data.string);
			case .Number: str.AppendF("{}", data.number);
			case .Bool:   str.Append(data.bool ? "true" : "false");
			default:
			}
		}
	}
}