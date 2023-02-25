using System;
using System.Collections;

namespace Cacti.Json;

enum JsonType {
	Null,
	Bool,
	Number,
	String,
	Array,
	Object
}

[Union, NoShow]
struct JsonData {
	public bool bool;
	public double number;
	public OwnableString string;
	public List<Json> list;
	public Dictionary<OwnableString, Json> dict;
}

struct Json : IDisposable {
	private static Json NULL = .(.Null, default, false);

	private JsonType type;

	private JsonData data;
	private bool ownsData;

	private this(JsonType type, JsonData data, bool ownsData) {
		this.type = type;

		this.data = data;
		this.ownsData = ownsData;
	}

	// Constructors

	public static Json Null() => NULL;

	public static Json Bool(bool bool) => .(.Bool, .() { bool = bool }, false);
	public static operator Self(bool bool) => Bool(bool);

	public static Json Number(double number) => .(.Number, .() { number = number }, false);
	public static operator Self(double number) => Number(number);
	
	public static Json String(OwnableString string) => .(.String, .() { string = string }, string case .Owned);

	public static Json Array(List<Json> list, bool owns = false) => .(.Array, .() { list = list }, owns);
	public static Json Array() => Array(new .(), true);

	public static Json Object(Dictionary<OwnableString, Json> dict, bool owns = false) => .(.Object, .() { dict = dict }, owns);
	public static Json Object() => Object(new .(), true);

	// Basic type methods

	public JsonType Type => type;

	public bool IsNull => type == .Null;
	public bool IsBool => type == .Bool;
	public bool IsNumber => type == .Number;
	public bool IsString => type == .String;
	public bool IsArray => type == .Array;
	public bool IsObject => type == .Object;

	public bool AsBool { get {
		if (IsBool) return data.bool;
		Runtime.FatalError(scope $"Tried to get a Json.Bool from a Json.{type}");
	} }

	public double AsNumber { get {
		if (IsNumber) return data.number;
		Runtime.FatalError(scope $"Tried to get a Json.Number from a Json.{type}");
	} }

	public StringView AsString { get {
		if (IsString) return data.string;
		Runtime.FatalError(scope $"Tried to get a Json.String from a Json.{type}");
	} }

	public List<Json> AsArray { get {
		if (IsArray) return data.list;
		Runtime.FatalError(scope $"Tried to get a Json.Array from a Json.{type}");
	} }

	public Dictionary<OwnableString, Json> AsObject { get {
		if (IsObject) return data.dict;
		Runtime.FatalError(scope $"Tried to get a Json.Object from a Json.{type}");
	} }

	// Object methods

	public ref Json this[StringView name] {
		get {
			let index = AsObject.[Friend]FindEntryAlt(name);
			if (index >= 0) return ref AsObject.[Friend]mEntries[index].mValue;

			return ref NULL;
		}
		set => Put(name, value, true);
	}

	public void Put(OwnableString name, Json value, bool copyName = true) {
		Remove(name);
		AsObject[copyName ? name.Copy() : name] = value;
	}

	public bool GetBool(StringView name, bool defaultValue = false) {
		if (!IsObject) return defaultValue;

		let element = this[name];
		return element.IsBool ? element.AsBool : defaultValue;
	}

	public double GetDouble(StringView name, double defaultValue = 0) {
		if (!IsObject) return defaultValue;

		let element = this[name];
		return element.IsNumber ? element.AsNumber : defaultValue;
	}

	public int GetInt(StringView name, int defaultValue = 0) => (.) GetDouble(name, defaultValue);

	public StringView GetString(StringView name, StringView defaultValue = "") {
		if (!IsObject) return defaultValue;

		let element = this[name];
		return element.IsString ? element.AsString : defaultValue;
	}

	public bool Contains(StringView name) {
		return AsObject.ContainsKeyAlt(name);
	}

	public bool Remove(StringView name) {
		switch (AsObject.GetAndRemoveAlt(name)) {
		case .Ok(let val):
			val.key.Dispose();
			val.value.Dispose();
			return true;

		case .Err:
			return false;
		}
	}

	// Array methods

	public ref Json this[int index] {
		get => ref AsArray[index];
		set => AsArray[index] = value;
	}

	public void Add(Json json) {
		AsArray.Add(json);
	}

	// Generic methods

	public void Clear() {
		switch (type) {
		case .Array:
			ClearAndDisposeItems!(data.list);
		case .Object:
			for (let (key, json) in data.dict) {
				key.Dispose();
				json.Dispose();
			}

			data.dict.Clear();
		default:
			Internal.FatalError(scope $"Can only clear Json.Array and Json.Object but got Json.{type}");
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

	public void Dispose() {
		switch (type) {
		case .String:
			if (ownsData) data.string.Dispose();

		case .Array:
			for (let child in data.list) {
				child.Dispose();
			}

			if (ownsData) delete data.list;

		case .Object:
			for (let pair in data.dict) {
				pair.key.Dispose();
				pair.value.Dispose();
			}
			
			if (ownsData) delete data.dict;

		default:
		}
	}
}