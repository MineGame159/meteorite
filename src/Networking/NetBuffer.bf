using System;

using Cacti;

namespace Meteorite {
	class NetBuffer {
		private int capacity;

		public int size, pos;
		public uint8* data ~ delete _;

		public this(int initialCapacity = 64) {
			capacity = initialCapacity;
			data = new uint8[initialCapacity]*;
		}

		public void EnsureCapacity(int additionalSize) {
			if (size + additionalSize > capacity) {
				capacity = Math.Max((int) (capacity * 1.5), size + additionalSize);

				uint8* newData = new uint8[capacity]*;
				Internal.MemCpy(newData, data, size);
				delete data;
				data = newData;
			}
		}

		public bool HasEnough(int needed) => needed >= 0 && size - pos >= needed;

		public void MoveToStart(int size) {
			Internal.MemCpy(data, &data[size], this.size - size);

			this.size -= size;
			pos = 0;
		}

		public void Skip(int size) {
			pos += size;
		}

		public Span<uint8> SpanAtPos => .(&data[pos], size - pos);

		// Write

		public void Write(uint8* data, int size) {
			EnsureCapacity(size);
			Internal.MemCpy(&this.data[this.size], data, size);
			this.size += size;
		}

		public void Write(NetBuffer buffer) {
			Write(buffer.data, buffer.size);
		}

		public void WriteBool(bool v) {
			data[size++] = v ? 1 : 0;
		}

		public void WriteUByte(uint8 v) {
			data[size++] = v;
		}

		public void WriteByte(int8 v) {
			*((int8*) &data[size++]) = v;
		}

		public void WriteUShort(uint16 v) {
			*((uint16*) &data[size]) = v;
			size += 2;
		}

		public void WriteShort(int16 v) {
			*((int16*) &data[size]) = v;
			size += 2;
		}

		public void WriteInt(int32 v) {
			*((int32*) &data[size]) = v;
			size += 4;
		}

		public void WriteLong(int64 v) {
			*((int64*) &data[size]) = v;
			size += 8;
		}

		public void WriteFloat(float v) {
			// TODO: Figure out a better way
			float vd = v;
			uint8* va = (.) &vd;
			uint8* d = &data[size];
			d[0] = va[3];
			d[1] = va[2];
			d[2] = va[1];
			d[3] = va[0];
			size += 4;
		}

		public void WriteDouble(double v) {
			// TODO: Figure out a better way
			double vd = v;
			uint8* va = (.) &vd;
			uint8* d = &data[size];
			d[0] = va[7];
			d[1] = va[6];
			d[2] = va[5];
			d[3] = va[4];
			d[4] = va[3];
			d[5] = va[2];
			d[6] = va[1];
			d[7] = va[0];
			size += 8;
		}

		public void WriteVarInt(int32 v) {
			var v;

			while ((v & -128) != 0) {
				data[size++] = (.) (v & 0x7F) | 0x80;
				v >>= 7;
			}

			data[size++] = (.) v;
		}

		public void WriteVarLong(int64 v) {
			var v;

			while ((v & -128) != 0) {
				data[size++] = (.) (v & 0x7F) | 0x80;
				v >>= 7;
			}

			data[size++] = (.) v;
		}

		public void WriteString(StringView v, int length = -1) {
			var length;
			if (length == -1) length = v.Length;

			WriteVarInt((.) length);
			EnsureCapacity(length);

			char8* c = v.ToScopeCStr!();
			Internal.MemCpy(&data[size], c, length);
			size += length;
		}

		public void WriteUUID(UUID uuid) {
			EnsureCapacity(16);

#unwarn
			Internal.MemCpy(&data[size], &uuid.bytes, 16);
			size += 16;
		}

		// Read

		public uint8* Read(int size) {
			uint8* buffer = &data[pos];
			pos += size;
			return buffer;
		}

		public uint8 ReadUByte() {
			return data[pos++];
		}

		public int8 ReadByte() {
			return *((int8*) &data[pos++]);
		}

		public bool ReadBool() {
			return ReadUByte() == 0 ? false : true;
		}

		public uint16 ReadUShort() {
			pos += 2;
			uint8[2] bytes = .(data[pos - 1], data[pos - 2]);
			return *(uint16*)(&bytes);
		}

		public int16 ReadShort() {
			pos += 2;
			uint8[2] bytes = .(data[pos - 1], data[pos - 2]);
			return *(int16*)(&bytes);
		}

		public int32 ReadInt() {
			pos += 4;
			uint8[4] bytes = .(data[pos - 1], data[pos - 2], data[pos - 3], data[pos - 4]);
			return *(int32*)(&bytes);
		}

		public int64 ReadLong() {
			pos += 8;
			uint8[8] bytes = .(data[pos - 1], data[pos - 2], data[pos - 3], data[pos - 4], data[pos - 5], data[pos - 6], data[pos - 7], data[pos - 8]);
			return *(int64*)(&bytes);
		}

		public float ReadFloat() {
			pos += 4;
			uint8[4] bytes = .(data[pos - 1], data[pos - 2], data[pos - 3], data[pos - 4]);
			return *(float*)(&bytes);
		}

		public double ReadDouble() {
			pos += 8;
			uint8[8] bytes = .(data[pos - 1], data[pos - 2], data[pos - 3], data[pos - 4], data[pos - 5], data[pos - 6], data[pos - 7], data[pos - 8]);
			return *(double*)(&bytes);
		}

		public int32 ReadVarInt() {
			int32 i = 0;
			int32 j = 0;

			for (;;) {
				uint32 k = data[pos++];
				i |= (k & 0x7F) << j++ * 7;
				if (j > 5 || (k & 0x80) != 128) break;
			}

			return i;
		}

		public int64 ReadVarLong() {
			int64 i = 0;
			int64 j = 0;

			for (;;) {
				uint32 k = data[pos++];
				i |= (k & 0x7F) << j++ * 7;
				if (j > 10 || (k & 0x80) != 128) break;
			}

			return i;
		}

		public String ReadString() {
			int32 size = ReadVarInt();
			String string = new .((char8*) &data[pos], size);
			pos += size;
			return string;
		}

		public Result<Tag> ReadNbt() {
			SpanMemoryStream s = scope .(SpanAtPos);
			Result<Tag> result = NbtReader.Read(s);
			Skip(s.Position);

			return result;
		}

		public float ReadAngle() {
			return ReadByte() * 360.0f / 256.0f;
		}

		public Vec3i ReadPosition() {
			int64 val = ReadLong();

			int x = (.) (val >> 38);
			int y = (.) (val & 0xFFF);
			int z = (.) ((val >> 12) & 0x03FFFFFF);

			if (x >= 1 << 25) x -= 1 << 26;
			if (y >= 1 << 11) y -= 1 << 12;
			if (z >= 1 << 25) z -= 1 << 26;

			return .(x, y, z);
		}

		public Text ReadText() {
			String str = ReadString();
			Json json = JsonParser.ParseString(str);

			Text text = .Parse(json);

			json.Dispose();
			delete str;

			return text;
		}

		// Other

		public static int GetVarIntSize(int32 v) {
			var v;
			int size = 0;

			while ((v & -128) != 0) {
			    size++;
			    v >>= 7;
			}

			return ++size;
		}
	}
}