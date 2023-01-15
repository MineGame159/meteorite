using System;

namespace Cacti {
	class Buffer {
		private uint8* data ~ delete _;
		private uint64 size, capacity, index;

		public this(uint64 defaultCapacity = 1024) {
			this.data = new .[defaultCapacity]*;
			this.capacity = defaultCapacity;
		}

		public uint8* Data => data;
		public uint64 Size => size;
		public uint64 Capacity => capacity;

		public void Clear() {
			size = 0;
			index = 0;
		}

		public void EnsureCapacity(uint64 additionalSize) {
			if (size + additionalSize <= capacity) return;

			uint64 newCapacity = Math.Max(size + additionalSize, (.) (size * 1.5));
			uint8* newData = new .[newCapacity]*;

			Internal.MemCpy(newData, data, (.) size);
			delete data;

			data = newData;
			capacity = newCapacity;
		}

		public void EnsureCapacity<T>(int count) where T : struct {
			EnsureCapacity((.) (sizeof(T) * count));
		}

		// Add

		public void Add<T>(T value) where T : struct {
			*((T*) &data[size]) = value;
			size += (.) sizeof(T);
		}

		public ref T Add<T>() where T : struct {
			size += (.) sizeof(T);
			return ref *((T*) &data[size - (.) sizeof(T)]);
		}

		public T* AddMultiple<T>(uint64 count) where T : struct {
			uint64 size = (.) sizeof(T) * count;

			this.size += size;
			return (T*) &data[this.size - size];
		}

		public void CopyTo(Buffer dst) {
			dst.EnsureCapacity(size);
			Internal.MemCpy(&dst.Data[dst.Size], data, (.) size);
			dst.[Friend]size += size;
		}

		// Get

		public ref T Get<T>() where T : struct {
			return ref *((T*) &data[index]);
		}

		public ref T Get<T>(uint64 index) where T : struct {
			return ref *((T*) &data[index]);
		}
	}
}