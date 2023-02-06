using System;

namespace System {
	extension Math {
		public const float DEG2RADf = PI_f / 180;
		public const double DEG2RADd = PI_d / 180;

		public const float RAD2DEGf = 180 / PI_f;
		public const double RAD2DEGd = 180 / PI_d;
	}

	extension Result<T> {
		public mixin GetOrPropagate() {
			if (this == .Err) return .Err;
			Value
		}
	}

	extension Result<T, E> {
		public mixin GetOrPropagate() {
			if (this case .Err) return .Err;
			Value
		}
	}

	extension StringView {
		public Self TrimInline() {
			Self string = this;
			string.Trim();
			return string;
		}

		public int Count(char8 c) {
			int count = 0;
			let ptr = Ptr;
			for (int i = 0; i < mLength; i++)
				if (ptr[i] == c)
					count++;
			return count;
		}
	}
}