using System;
using System.Collections;

using Shaderc;

namespace Cacti.Graphics;

typealias ShaderPreProcessCallback = delegate void(ShaderPreProcessOptions options);

class ShaderPreProcessOptions {
	private BumpAllocator alloc = new .() ~ delete _;
	private List<ShaderDefine> defines = new:alloc .();

	public Span<ShaderDefine> Defines => defines;

	public void Define(StringView name, StringView value = "TRUE") {
		defines.Add(new:alloc .(name, value));
	}
}