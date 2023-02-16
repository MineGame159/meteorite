using System;
using System.IO;

using Cacti;

namespace Meteorite;

static class NbtReader {
	public static Result<Tag> Read(Stream s) {
		uint8 id = s.Read<uint8>();
		if (id == (.) TagType.End) return .Err;

		String a = scope .();
		ReadString(s, a);

		Tag tag = ReadTag(s, (.) id);
		if (!tag.IsCompound) {
			tag.Dispose();
			return .Err;
		}

		return tag;
	}

	private static Tag ReadCompount(Stream s) {
		Tag tag = .Compound();

		for (;;) {
			TagType type = (.) s.Read<uint8>();
			if (type == .End) break;

			String name = scope .();
			ReadString(s, name);

			tag[name] = ReadTag(s, type);
		}

		return tag;
	}

	private static Tag ReadTag(Stream s, TagType type) {
		switch (type) {
		case .Byte: return .Byte(s.Read<int8>());
		case .Short: return .Short(ReadShort(s));
		case .Int: return .Int(ReadInt(s));
		case .Long: return .Long(ReadLong(s));
		case .Float: return .Float(ReadFloat(s));
		case .Double: return .Double(ReadDouble(s));
		case .ByteArray:
			uint8[] bytes = new uint8[ReadInt(s)];
			s.TryRead(bytes);
			return .Bytes(bytes);
		case .String:
			String str = new .();
			ReadString(s, str);
			return .StringOwn(str);
		case .List:
			TagType t = (.) s.Read<uint8>();
			int count = ReadInt(s);
			Tag tag = .List(count);

			for (int i < count) tag.Add(ReadTag(s, t));

			return tag;
		case .Compound: return ReadCompount(s);
		case .IntArray:
			int32[] ints = new int32[ReadInt(s)];
			for (int i < ints.Count) ints[i] = ReadInt(s);
			return .Ints(ints);
		case .LongArray:
			int64[] longs = new int64[ReadInt(s)];
			for (int i < longs.Count) longs[i] = ReadLong(s);
			return .Longs(longs);
		default: return default;
		}
	}

	private static void ReadString(Stream s, String buffer) {
		uint16 length = ((uint16) (s.Read<uint8>() & 0xFF) << 8) | (uint16) (s.Read<uint8>() & 0xFF);
		
		for (int i < length) {
			buffer.Append(s.Read<char8>());
		}

		return;
	}

	private static int16 ReadShort(Stream s) => Utils.SwapBytes(s.Read<int16>().Value);
	private static int32 ReadInt(Stream s) => Utils.SwapBytes(s.Read<int32>().Value);
	private static int64 ReadLong(Stream s) => Utils.SwapBytes(s.Read<int64>().Value);
	
	private static float ReadFloat(Stream s) => Utils.SwapBytes(s.Read<float>().Value);
	private static double ReadDouble(Stream s) => Utils.SwapBytes(s.Read<double>().Value);
}