using System;

namespace Cacti;

struct UUID : this(uint8[16] bytes) {
	private const int[?] IDK = .(
		0, 2, 4, 6,
		9, 11,
		14, 16,
		19, 21,
		24, 26, 28, 30, 32, 34
	);

	public static Result<Self> Parse(StringView str, bool allowEmpty = false) {
		if (str.IsEmpty && allowEmpty) {
			return UUID(default);
		}

		// xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
		if (str.Length == 36) {
			char8 ch1 = str[8];
			char8 ch2 = str[13];
			char8 ch3 = str[18];
			char8 ch4 = str[23];
	
			if (ch1 != '-' || ch2 != '-' || ch3 != '-' || ch4 != '-') {
				return .Err;
			}
	
			uint8[16] bytes = ?;
			int i = 0;
	
			for (int x in IDK) {
				let (v, ok) = Utils.HexToByte(str[x], str[x + 1]);
	
				if (!ok) {
					return .Err;
				}
	
				bytes[i++] = v;
			}
	
			return UUID(bytes);
		}
		// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		else if (str.Length == 32) {
			uint8[16] bytes = ?;

			for (int i < 16) {
				let (v, ok) = Utils.HexToByte(str[i * 2], str[i * 2 + 1]);

				if (!ok) {
					return .Err;
				}

				bytes[i] = v;
			}

			return UUID(bytes);
		}

		return .Err;
	}

	public void ToString(String str, bool dashes = true) {
		// There is a warning because I am taking the address to bytes while this method is not marked as mutable but it should not matter as it is not being modified
#pragma warning disable 4204
		Utils.HexEncode(.(&bytes, 4), str);
		if (dashes) str.Append('-');

		Utils.HexEncode(.(&bytes[4], 2), str);
		if (dashes) str.Append('-');

		Utils.HexEncode(.(&bytes[6], 2), str);
		if (dashes) str.Append('-');

		Utils.HexEncode(.(&bytes[8], 2), str);
		if (dashes) str.Append('-');

		Utils.HexEncode(.(&bytes[10], 6), str);
#pragma warning restore 4204
	}

	public override void ToString(String str) => ToString(str, true);
}