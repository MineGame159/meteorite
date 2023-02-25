using System;
using System.IO;

namespace Cacti;

interface IWriter {
	Result<void> Write(StringView string);

	Result<void> Write(char8 char);
}

abstract class BaseWriter : IWriter {
	public abstract Result<void> Write(StringView string);

	public abstract Result<void> Write(char8 char);

	public void WriteLine(StringView string) {
		Write(string);
		Write('\n');
	}
}

class StringWriter : BaseWriter {
	private String string;

	public this(String string) {
		this.string = string;
	}

	public override Result<void> Write(StringView string) {
		this.string.Append(string);
		return .Ok;
	}

	public override Result<void> Write(char8 char) {
		this.string.Append(char);
		return .Ok;
	}
}

class MyStreamWriter : BaseWriter {
	private Stream stream;

	public this(Stream stream) {
		this.stream = stream;
	}

	public override Result<void> Write(StringView string) {
		return stream.TryWrite(.((.) string.Ptr, string.Length)).IgnoreValue();
	}

	public override Result<void> Write(char8 char) {
#unwarn
		return stream.TryWrite(.((.) &char, 1)).IgnoreValue();
	}
}