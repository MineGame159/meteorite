using System;
using System.Collections;

namespace Meteorite;

class PropertyInfo {
	public StringView name;
	public int min, max;
	public List<StringView> names ~ delete _;

	public this(StringView name, int min, int max, params StringView[] names) {
		this.name = name;
		this.min = min;
		this.max = max;
		
		this.names = new .(names.Count);
		this.names.AddRange(names);
	}

	public static PropertyInfo Bool(StringView name) => new .(name, 0, 1, "true", "false");
	public static PropertyInfo Int(StringView name, int min, int max) => new .(name, min, max);
	public static PropertyInfo Enum(StringView name, params StringView[] names) => new .(name, 0, names.Count - 1, params names);
}

struct Property : this(PropertyInfo info, int value) {
	public void GetValueString(String str) {
		if (info.names.IsEmpty) value.ToString(str);
		else str.Append(info.names[value]);
	}
}