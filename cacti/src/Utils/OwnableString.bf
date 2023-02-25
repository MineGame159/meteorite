using System;

namespace Cacti;

enum OwnableString : IEquatable<Self>, IEquatable<StringView>, IEquatable<String>, IEquatable, IHashable, IDisposable {
	case View(StringView string);
	case Owned(String string);

	public StringView String { get {
		switch (this) {
		case .View(let string):		return string;
		case .Owned(let string):	return string;
		}
	} }

	public bool IsEmpty => String.IsEmpty;

	public Self Copy() => .Owned(new .(String));

	public bool Equals(OwnableString other) => String == other.String;
	public bool Equals(StringView other) => String == other;
	public bool Equals(String other) => String == other;

	public bool Equals(Object other) {
		if (other is OwnableString) return Equals((OwnableString) other);
		if (other is StringView) return Equals((StringView) other);
		if (other is String) return Equals((String) other);

		return false;
	}
	
	public int GetHashCode() => String.GetHashCode();

	public void Dispose() {
		if (this case .Owned(let string)) {
			delete string;
		}
	}

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);

	[Commutable]
	public static bool operator==(Self lhs, StringView rhs) => lhs.Equals(rhs);

	[Commutable]
	public static bool operator==(Self lhs, String rhs) => lhs.Equals(rhs);

	public static operator Self(StringView string) => .View(string);
	public static operator Self(String string) => .View(string);

	public static operator StringView(Self ownable) => ownable.String;
}