using System;

namespace Meteorite;

class ResourceKey : IEquatable<Self>, IEquatable, IHashable {
	private String key;
	private int separator;

	public StringView Full => key;

	public StringView Namespace => key.Substring(0, separator);
	public StringView Path => key.Substring(separator + 1);

	[AllowAppend]
	public this(StringView key) {
		String _key = append .(key);

		this.key = _key;
		this.separator = key.IndexOf(':');
	}

	[AllowAppend]
	public this(StringView namespac, StringView path) {
		String _key = append .(namespac.Length + 1 + path.Length);
		this.key = _key;

		key.Append(namespac);
		key.Append(':');
		key.Append(path);

		separator = namespac.Length;
	}

	[AllowAppend]
	public this(Self key) {
		String _key = append .(key.key);

		this.key = _key;
		this.separator = key.separator;
	}

	public bool Equals(Self other) => key == other.key;

	public bool Equals(Object other) => (other is Self) ? Equals((Self) other) : false;

	public int GetHashCode() => key.GetHashCode();

	public override void ToString(String str) {
		str.Append(key);
	}

	public static operator StringView(Self key) => key.Full;

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}