using System;

namespace Meteorite {
	class BitSet {
		private const int ADDRESS_BITS_PER_WORD = 6;
		private const int BITS_PER_WORD = 1 << ADDRESS_BITS_PER_WORD;

		private uint64[] words;

		[AllowAppend]
		public this(int count) {
			uint64[] w = append .[WordIndex!(count - 1) + 1];
			words = w;
		}

		[Inline]
		public void Set(int index) {
			words[WordIndex!(index)] |= 1UL << index;
		}

		[Inline]
		public void Clear(int index) {
			words[WordIndex!(index)] &= ~(1UL << index);
		}

		public void Set(int index, bool value) {
			if (value) Set(index);
			else Clear(index);
		}
		
		[Inline]
		public bool Get(int index) {
			return (words[WordIndex!(index)] & (1UL << index)) != 0;
		}

		private static mixin WordIndex(int index) {
		    index >> ADDRESS_BITS_PER_WORD
		}
	}
}