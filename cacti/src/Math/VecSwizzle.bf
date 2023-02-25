using System;
using System.Collections;

namespace Cacti;

/*[AttributeUsage(.Struct)]
struct VecSwizzleAttribute : this(int components), Attribute, IOnTypeInit {
	struct Pos : this(int x, int y, int z, int w), IHashable {
		public int GetHashCode() => x * y * z * w;
	}

	[Comptime]
	public void OnTypeInit(Type type, Self* prev) {
		String string = scope .();

		// Initialize positions
		int[4] positions = .();
		bool stop = false;

		mixin Increment() {
			positions[0]++;

			for (int pos < 4) {
				if (positions[pos] >= components) {
					positions[pos] = 0;

					if (pos + 1 < 4) positions[pos + 1]++;
					else stop = true;
				}
			}
		}

		// Generate
		HashSet<Pos> generated = scope .();

		while (!stop) {
			for (int i = 2; i <= components; i++) {
				// Skip if already generated
				Pos pos = .(positions[0], positions[1], positions[2], positions[3]);

				if (i < 4) pos.w = 0;
				if (i < 3) pos.z = 0;

				if (generated.Contains(pos)) continue;
				generated.Add(pos);

				// Generate
				string.AppendF("[NoShow] public Vec{}<T> ", i);

				for (int k < i) {
					string.Append(GetComponentName(positions[k], true));
				}

				string.Append(" => .(");

				for (int k < i) {
					if (k > 0) string.Append(", ");
					string.Append(GetComponentName(positions[k]));
				}

				string.Append(");\n");
			}

			Increment!();
		}

		Compiler.EmitTypeBody(type, string);
	}

	private int GetNumberOfCombinations(int components) {
		int count = 1;

		for (int i = 1; i <= components; i++) {
			count *= i;
		}

		return count;
	}

	private char8 GetComponentName(int component, bool uppercase = false) {
		switch (component) {
		case 0:		return uppercase ? 'X' : 'x';
		case 1: 	return uppercase ? 'Y' : 'y';
		case 2: 	return uppercase ? 'Z' : 'z';
		case 3: 	return uppercase ? 'W' : 'w';
		default:	Runtime.FatalError();
		}
	}
}*/