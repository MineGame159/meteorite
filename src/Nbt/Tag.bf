using System;
using System.Collections;

namespace Meteorite {
	enum TagType {
		End,
		Byte,
		Short,
		Int,
		Long,
		Float,
		Double,
		ByteArray,
		String,
		List,
		Compound,
		IntArray,
		LongArray
	}

	[Union]
	struct TagData {
		public int8 byte;
		public int16 short;
		public int32 int;
		public int64 long;
		public float float;
		public double double;
		public uint8[] bytes;
		public String string;
		public List<Tag> list;
		public Dictionary<String, Tag> compound;
		public int32[] ints;
		public int64[] longs;
	}

	struct Tag : IDisposable {
		public TagType type;
		private TagData data;

		public this(TagType type, TagData data) {
			this.type = type;
			this.data = data;
		}

		public static Tag Byte(int8 v) {
			TagData data;
			data.byte = v;

			return .(.Byte, data);
		}

		public static Tag Short(int16 v) {
			TagData data;
			data.short = v;

			return .(.Short, data);
		}

		public static Tag Int(int32 v) {
			TagData data;
			data.int = v;

			return .(.Int, data);
		}

		public static Tag Long(int64 v) {
			TagData data;
			data.long = v;

			return .(.Long, data);
		}

		public static Tag Float(float v) {
			TagData data;
			data.float = v;

			return .(.Float, data);
		}

		public static Tag Double(double v) {
			TagData data;
			data.double = v;

			return .(.Double, data);
		}

		public static Tag Bytes(uint8[] v) {
			TagData data;
			data.bytes = v;

			return .(.ByteArray, data);
		}

		public static Tag String(StringView v) {
			TagData data;
			data.string = new .(v);

			return .(.String, data);
		}

		public static Tag StringOwn(String v) {
			TagData data;
			data.string = v;

			return .(.String, data);
		}

		public static Tag List() {
			TagData data;
			data.list = new .();

			return .(.List, data);
		}

		public static Tag List(int initialCapacity) {
			TagData data;
			data.list = new .(initialCapacity);

			return .(.List, data);
		}

		public static Tag Compound() {
			TagData data;
			data.compound = new .();

			return .(.Compound, data);
		}

		public static Tag Ints(int32[] v) {
			TagData data;
			data.ints = v;

			return .(.IntArray, data);
		}

		public static Tag Longs(int64[] v) {
			TagData data;
			data.longs = v;

			return .(.LongArray, data);
		}

		public bool IsByte => type == .Byte;
		public bool IsShort => type == .Short;
		public bool IsInt => type == .Int;
		public bool IsLong => type == .Long;
		public bool IsFloat => type == .Float;
		public bool IsDouble => type == .Double;
		public bool IsBytes => type == .ByteArray;
		public bool IsString => type == .String;
		public bool IsList => type == .List;
		public bool IsCompound => type == .Compound;
		public bool IsInts => type == .IntArray;
		public bool IsLongs => type == .LongArray;

		public int8 AsByte => data.byte;
		public int16 AsShort => data.short;
		public int32 AsInt => data.int;
		public int64 AsLong => data.long;
		public float AsFloat => data.float;
		public double AsDouble => data.double;
		public uint8[] AsBytes => data.bytes;
		public String AsString => data.string;
		public List<Tag> AsList => data.list;
		public Dictionary<String, Tag> AsCompound => data.compound;
		public int32[] AsInts => data.ints;
		public int64[] AsLongs => data.longs;

		public Tag this[String key] {
			get => AsCompound.GetValueOrDefault(key);
			set { Remove(key); AsCompound[new .(key)] = value; }
		}

		public void Add(Tag tag) {
			AsList.Add(tag);
		}

		public bool Contains(String key) => !AsCompound.ContainsKey(key);

		public void Remove(String key) {
			if (AsCompound.GetAndRemove(key) case .Ok(let pair)) {
				delete pair.key;
				pair.value.Dispose();
			}
		}

		public void Dispose() {
			switch (type) {
			case .ByteArray: delete AsBytes;
			case .String: delete AsString;
			case .List: DeleteContainerAndDisposeItems!(AsList);
			case .Compound:
				for (let pair in AsCompound) {
					delete pair.key;
					pair.value.Dispose();
				}

				delete AsCompound;
			case .IntArray: delete AsInts;
			case .LongArray: delete AsLongs;
			default:
			}
		}
	}
}