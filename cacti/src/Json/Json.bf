using System;
using System.Collections;

namespace Cacti {
	enum JsonType {
		Null,
		Object,
		Array,
		String,
		Number,
		Bool,
		DirectWrite
	}

	interface ICustomJson {
		void Write(String buffer);
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

		public static Json Null() {
			return .(.Null, .());
		}

		public static Json Object() {
			JsonData data;
			data.object = new .();

			return .(.Object, data);
		}

		public static Json Array(List<Json> array = null) {
			JsonData data;
			data.array = array == null ? new .() : array;

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

		public static Json DirectWrite(String str) {
			JsonData data;
			data.string = str;

			return .(.DirectWrite, data);
		}

		public bool IsNull => type == .Null;
		public bool IsObject => type == .Object;
		public bool IsArray => type == .Array;
		public bool IsString => type == .String;
		public bool IsNumber => type == .Number;
		public bool IsBool => type == .Bool;
		public bool IsDirectWrite => type == .DirectWrite;

		public Dictionary<String, Json> AsObject => data.object;
		public List<Json> AsArray => data.array;
		public String AsString => data.string;
		public double AsNumber => data.number;
		public bool AsBool => data.bool;

		public Json this[StringView key]{
			get {
				String _key;
				Json value;
				if (AsObject.TryGetAlt(key, out _key, out value)) return value;
				return .Null();
			}
			set {
				Remove(key);
				AsObject[new .(key)] = value;
			}
		}

		public Json this[int key] {
			get => AsArray[key];
		}

		public void Add(Json json) {
			AsArray.Add(json);
		}

		public bool Contains(StringView key) => !this[key].IsNull;

		public bool GetBool(String key, bool defaultValue = false) {
			if (!IsObject) return defaultValue;

			let json = this[key];
			return json.IsBool ? json.AsBool : defaultValue;
		}

		public int GetInt(String key, int defaultValue) {
			if (!IsObject) return defaultValue;

			let json = this[key];
			return json.IsNumber ? (.) json.AsNumber : defaultValue;
		}

		public void Remove(StringView key) {
			if (AsObject.GetAndRemoveAlt(key) case .Ok(let pair)) {
				delete pair.key;
				pair.value.Dispose();
			}
		}

		public void Merge(Json json, delegate bool(StringView) mergeKey) {
			if (IsObject) {
				for (let pair in json.AsObject) {
					if (!mergeKey(pair.key)) continue;

					switch (pair.value.type) {
					case .Object:
						Json a = this[pair.key];
						if (!a.IsObject) {
							a = .Object();
							this[pair.key] = a;
						}

						a.Merge(pair.value, mergeKey);
					case .Array:
						Json a = this[pair.key];
						if (!a.IsArray) {
							a = .Array();
							this[pair.key] = a;
						}

						a.Merge(pair.value, mergeKey);
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

						a.Merge(j, mergeKey);
					case .Array:
						Json a = .Array();
						Add(a);

						a.Merge(j, mergeKey);
					case .String: Add(.String(j.AsString));
					case .Number, .Bool: Add(j);
					default:
					}
				}
			}
		}
		public void Merge(Json json) => Merge(json, scope (key) => true);

		public Json Copy() {
			switch (type) {
			case .Null:        return .Null();
			case .Object:
				Json json = .Object();
				for (let pair in AsObject) json[pair.key] = pair.value.Copy();
				return json;
			case .Array:
				Json json = .Array();
				for (let item in AsArray) json.Add(item.Copy());
				return json;
			case .String:      return .String(AsString);
			case .Number:      return .Number(AsNumber);
			case .Bool:        return .Bool(AsBool);
			case .DirectWrite: return .DirectWrite(new .(AsString));
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
			else if (IsString || IsDirectWrite) {
				delete AsString;
			}
		}

		public override void ToString(String str) {
			switch (type) {
			case .Null:        str.Append("null");
			case .String:      str.Append(AsString);
			case .Number:      str.AppendF("{}", AsNumber);
			case .Bool:        str.Append(AsBool ? "true" : "false");
			case .DirectWrite: str.Append(AsString);
			default:
			}
		}
	}
}