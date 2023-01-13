using System;

namespace Meteorite;

static class NbtWriter {
	public static void Write(Tag tag, String buffer) {
		switch (tag.type) {
		case .Byte:			buffer.Append(tag.AsByte);
		case .Short:		buffer.Append(tag.AsShort);
		case .Int:			buffer.Append(tag.AsInt);
		case .Long:			buffer.Append(tag.AsLong);
		case .Float:		buffer.Append(tag.AsFloat);
		case .Double:		buffer.Append(tag.AsDouble);
		case .ByteArray:	WriteByteArray(tag, buffer);
		case .String:		buffer..Append('"')..Append(tag.AsString).Append('"');
		case .List:			WriteList(tag, buffer);
		case .Compound:		WriteCompound(tag, buffer);
		case .IntArray:		WriteIntArray(tag, buffer);
		case .LongArray:	WriteLongArray(tag, buffer);
		default:
		}
	}

	private static void WriteByteArray(Tag tag, String buffer) {
		buffer.Append('[');

		int i = 0;
		for (let child in tag.AsBytes) {
			if (i++ > 0) buffer.Append(',');
			buffer.Append(child);
		}

		buffer.Append(']');
	}

	private static void WriteList(Tag tag, String buffer) {
		buffer.Append('[');

		int i = 0;
		for (let child in tag.AsList) {
			if (i++ > 0) buffer.Append(',');
			Write(child, buffer);
		}

		buffer.Append(']');
	}

	private static void WriteCompound(Tag tag, String buffer) {
		buffer.Append('{');

		int i = 0;
		for (let (name, child) in tag.AsCompound) {
			if (i++ > 0) buffer.Append(',');

			buffer.Append('"');
			buffer.Append(name);
			buffer.Append("\":");

			Write(child, buffer);
		}

		buffer.Append('}');
	}

	private static void WriteIntArray(Tag tag, String buffer) {
		buffer.Append('[');

		int i = 0;
		for (let child in tag.AsInts) {
			if (i++ > 0) buffer.Append(',');
			buffer.Append(child);
		}

		buffer.Append(']');
	}

	private static void WriteLongArray(Tag tag, String buffer) {
		buffer.Append('[');

		int i = 0;
		for (let child in tag.AsLongs) {
			if (i++ > 0) buffer.Append(',');
			buffer.Append(child);
		}

		buffer.Append(']');
	}
}