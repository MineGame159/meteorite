using System;
using System.IO;

namespace Meteorite {
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
			case .Short: return .Short((int16) ((int16) s.Read<uint8>() << 8) | (int16) (s.Read<uint8>() & 0xff));
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

		private static int32 ReadInt(Stream s) => (int16) ((int32) (s.Read<uint8>() & 0xff) << 24) | (int16) ((int32) (s.Read<uint8>() & 0xff) << 16) | (int16) ((s.Read<uint8>() & 0xff) <<  8) | (int16) (s.Read<uint8>() & 0xff);
		private static int64 ReadLong(Stream s) => (int64) ((s.Read<uint8>() & 0xff) << 56) | (int64) ((s.Read<uint8>() & 0xff) << 48) | (int64) ((s.Read<uint8>() & 0xff) << 40) | (int64) ((s.Read<uint8>() & 0xff) << 32) | (int64) ((s.Read<uint8>() & 0xff) << 24) | (int64) ((s.Read<uint8>() & 0xff) << 16) | (int64) ((s.Read<uint8>() & 0xff) <<  8) | (int64) ((s.Read<uint8>() & 0xff));

		private static float ReadFloat(Stream s) {
			uint8[4] bytes = ?;
			s.TryRead(bytes);

			uint8[4] bytes2 = .(
				bytes[3],
				bytes[2],
				bytes[1],
				bytes[0]
			);

			return *((float*) &bytes2);
		}

		private static double ReadDouble(Stream s) {
			uint8[8] bytes = ?;
			s.TryRead(bytes);

			uint8[8] bytes2 = .(
				bytes[7],
				bytes[6],
				bytes[5],
				bytes[4],
				bytes[3],
				bytes[2],
				bytes[1],
				bytes[0]
			);

			return *((double*) &bytes2);
		}
	}
}