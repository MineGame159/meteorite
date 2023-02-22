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

class ShaderSource : IEquatable<Self>, IEquatable, IHashable {
	private ShaderSourceType type;
	private String string;

	public ShaderSourceType Type => type;
	public StringView String => string;

	[AllowAppend]
	private this(ShaderSourceType type, StringView string) {
		String _string = append .(string);

		this.type = type;
		this.string = _string;
	}

	public static Self String(StringView string) => new .(.String, string);
	public static Self File(StringView string) => new .(.File, string);

	public Self Copy() => new .(type, string);

	public bool Equals(ShaderSource other) => type == other.type && string == other.string;

	public bool Equals(Object other) => other is Self && Equals((Self) other);

	public int GetHashCode() => Utils.CombineHashCode(type.Underlying, string.GetHashCode());

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}

class Shader : DoubleRefCounted{
	// Fields

	private VkShaderModule handle ~ vkDestroyShaderModule(Gfx.Device, _, null);

	private ShaderType type;

	private append ShaderInfo info = .();

	private bool valid = true;

	// Properties
	
	public VkShaderModule Vk => handle;

	public ShaderType Type => type;

	public ShaderInfo Info => info;

	// Constructors / Destructors

	private this(VkShaderModule handle, ShaderType type) {
		this.handle = handle;
		this.type = type;
	}

	private Result<void> Reflect(uint size, void* code) {
		ShaderReflect reflect = scope .();
		reflect.Create(code, size).GetOrPropagate!();

		info.Clear();
		return reflect.Get(info);
	}

	// Reference counting

	protected override void Delete() {
		if (valid) {
			AddWeakRef();
			Gfx.ReleaseNextFrame(this);

			valid = false;
		}
		else {
			delete this;
		}
	}
}