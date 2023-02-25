using System;

namespace Cacti.Json;

class JsonTree {
	private BumpAllocator alloc = new .();

	public Json root = .Null();

	public ~this() {
		root.Dispose();
		delete alloc;
	}

	public Json String(StringView value) => .String(new:alloc String(value));

	public Json Array() => .Array(new:alloc .());

	public Json Object() => .Object(new:alloc .());
}