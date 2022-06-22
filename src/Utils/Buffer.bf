using System;

namespace Meteorite {
	class Buffer {
		public uint8* data ~ delete _;
		public int size;

		private int capacity;

		public this(int initialCapacity) {
			data = new uint8[initialCapacity]*;
			capacity = initialCapacity;
		}

		public void Clear() => size = 0;

		public void EnsureCapacity(int additionalSize) {
			if (size + additionalSize > capacity) {
				capacity = Math.Max((int) (capacity * 1.5), size + additionalSize);

				uint8* newData = new uint8[capacity]*;
				Internal.MemCpy(newData, data, size);
				delete data;
				data = newData;
			}
		}

		public void UByte(uint8 v) => data[size++] = v;
		public void Byte(int8 v) => *((int8*) &data[size++]) = v;

		public void UShort(uint16 v) {
			*((uint16*) &data[size]) = v;
			size += sizeof(uint16);
		}

		public void UInt(uint32 v) {
			*((uint32*) &data[size]) = v;
			size += sizeof(uint32);
		}

		public void Float(float v) {
			*((float*) &data[size]) = v;
			size += sizeof(float);
		}
	}
}