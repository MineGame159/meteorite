using System;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

using Shaderc;

namespace Cacti.Graphics;

enum ShaderType {
	Vertex,
	Fragment
}

enum ShaderSourceType {
	String,
	File
}

class ShaderSource : IHashable, IEquatable, IEquatable<Self> {
	private ShaderSourceType type;
	private append String string = .();

	public ShaderSourceType Type => type;
	public StringView String => string;

	private this(ShaderSourceType type, StringView string) {
		this.type = type;
		this.string.Set(string);
	}

	public static Self String(StringView string) => new .(.String, string);
	public static Self File(StringView string) => new .(.File, string);

	public Self Copy() => new .(type, string);

	public bool Equals(Object other) {
		return other is Self && Equals((Self) other);
	}

	public bool Equals(ShaderSource other) {
		return type == other.type && string == other.string;
	}

	public int GetHashCode() {
		return Utils.CombineHashCode(type.Underlying, string.GetHashCode());
	}
}

struct ShaderPreProcessor {
	private Shaderc.CompileOptions options;

	private this(Shaderc.CompileOptions options) {
		this.options = options;
	}

	public void Define(StringView name, StringView value = "TRUE") {
		options.AddMacroDefinition(name, value);
	}
}

delegate void ShaderPreProcessCallback(ShaderPreProcessor preProcessor);

class Shader {
	// Fields

	private VkShaderModule handle ~ vkDestroyShaderModule(Gfx.Device, _, null);

	private ShaderType type;
	private ShaderSource source;
	private RefCounted<ShaderPreProcessCallback> preProcessCallback ~ _?.Release();

	private append ShaderInfo info = .();

	// Properties
	
	public VkShaderModule Vk => handle;

	public ShaderType Type => type;

	public ShaderInfo Info => info;

	// Constructors / Destructors

	private this(VkShaderModule handle, ShaderType type, ShaderSource source, RefCounted<ShaderPreProcessCallback> preProcessCallback) {
		this.handle = handle;
		this.type = type;
		this.source = source;
		this.preProcessCallback = preProcessCallback != null ? preProcessCallback..AddRef() : null;
	}

	private Result<void> Reflect(uint size, void* code) {
		ShaderReflect reflect = scope .();
		reflect.Create(code, size).GetOrPropagate!();

		info.Clear();
		return reflect.GetDescriptors(info);
	}

	// Shader

	public Result<void> Reload() {
		vkDestroyShaderModule(Gfx.Device, handle, null);

		let (handle, result) = Gfx.Shaders.[Friend]CreateRaw(type, source, preProcessCallback?.Value).GetOrPropagate!();

		this.handle = handle;
		defer delete result;

		return Reflect(result.SpvLength * 4, result.Spv);
	}
}