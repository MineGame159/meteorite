using System;
using System.IO;
using System.Collections;

using Cacti.Crypto;

using Bulkan;
using static Bulkan.VulkanNative;

using Shaderc;

namespace Cacti.Graphics;

class ShaderManager {
	private Dictionary<Info, Entry> entries = new .() ~ delete _;
				
	private ShaderPreProcessor preProcessor = new .() ~ delete _;
	private Shaderc.CompileOptions options = new .() ~ delete _;

	public int Count => entries.Count;

	public this() {
		// Setup compiler options
#if DEBUG
		options.SetGenerateDebugInfo();
		options.SetOptimizationLevel(.Zero);
#elif RELEASE
		preProcessor.PreserveLineCount = false;
		options.SetOptimizationLevel(.Performance);
#endif

		// Setup read callback
		preProcessor.SetReadCallback(new (path, output) => {
			String buffer = scope .();
			File.ReadAllText(path, buffer).GetOrPropagate!();

			output.Append(buffer);
			return .Ok;
		});
	}

	public void Destroy() {
		for (let (info, entry) in entries) {
			info.Dispose();
			delete entry;
		}

		entries.Clear();
	}

	public void SetReadCallback(ShaderReadCallback callback) {
		preProcessor.SetReadCallback(callback);
	}

	[Tracy.Profile]
	public Result<Shader> Get(ShaderType type, ShaderSource source, RefCounted<ShaderPreProcessCallback> prePreprocessCallback = null) {
		// Get info
		ShaderPreProcessOptions preProcessor = scope .();
		prePreprocessCallback?.Value(preProcessor);

		Info info = .Point(type, source, preProcessor);

		// Check cache
		Entry entry;

		if (entries.TryGetValue(info, out entry)) {
			return entry.shader;
		}

		// Create shader
		entry = new .(type, source, prePreprocessCallback);
		entry.Reload(info).GetOrPropagate!();
		
		entries[.Copy(info)] = entry;
		
		return entry.shader;
	}

	[Tracy.Profile]
	public Result<void> Reload() {
		// Reload shaders
		for (let entry in entries.Values) {
			entry.Reload().GetOrPropagate!();
		}

		// Reload pipelines
		for (Pipeline pipeline in Gfx.Pipelines.[Friend]pipelines) {
			pipeline.ReloadIfOutdatedShaders().GetOrPropagate!();
		}

		return .Ok;
	}

	[Tracy.Profile(variable=true)]
	private Result<void> PreProcess(Info info, RefCounted<ShaderPreProcessCallback> preProcessCallback, String preProcessedSource, String fileName) {
		// Get source string and file name
		String source = scope .();
		
		GetSource(info, source, fileName).GetOrPropagate!();
		__tracy_zone.AddText(fileName);

		List<ShaderDefine> defines = scope .(info.defines.Length + 1);

		info.defines.CopyTo(defines);
		defines.[Friend]mSize += (.) info.defines.Length;

		if (info.type == .Vertex) {
			defines.Add(scope:: .("VERTEX", "TRUE"));
		}
		else {
			defines.Add(scope:: .("FRAGMENT", "TRUE"));
		}

		// Pre-process
		if (preProcessor.PreProcess(fileName, source, defines, preProcessedSource) case .Err(let err)) {
			Log.Error("Failed to compile shader '{}' at line {}: {}", err.file, err.line, err.message);
			return .Err;
		}

		return .Ok;
	}

	[Tracy.Profile(variable=true)]
	private Result<Shader> Create(Info info, StringView source, StringView sourceName) {
		__tracy_zone.AddText(sourceName);

		// Compile to SPIR-V
		let (compiler, options, kind) = GetCompiler!(info);

		Shaderc.CompilationResult result = compiler.CompileIntoSpv(source, kind, sourceName, "main", options);
		defer delete result;

		if (result.Status != .Success) {
			Log.Error("Failed to compile shader '{}': {}", sourceName, result.ErrorMessage);
			return .Err;
		}

		// Create
		VkShaderModule module = CreateRaw(result, sourceName).GetOrPropagate!();

		Shader shader = new [Friend].(module, info.type);
		shader.[Friend]Reflect(result.SpvLength * 4, result.Spv).GetOrPropagate!();

		return shader;
	}

	private Result<void> GetSource(Info info, String source, String sourceName) {
		if (info.source.Type == .String) {
			source.Set(info.source.String);
			sourceName.Set("<inline>");
		}
		else {
			preProcessor.ReadShader(info.source.String, source).GetOrPropagate!();
			sourceName.Set(info.source.String);
		}

		return .Ok;
	}
	
	private mixin GetCompiler(Info info) {
		Shaderc.Compiler compiler = scope:mixin .();
		Shaderc.CompileOptions options = scope:mixin .(options);
		Shaderc.ShaderKind kind;

		switch (info.type) {
		case .Vertex:
			options.AddMacroDefinition("VERTEX", "TRUE");
			kind = .Vertex;

		case .Fragment:
			options.AddMacroDefinition("FRAGMENT", "TRUE");
			kind = .Fragment;
		}

		for (let define in info.defines) {
			options.AddMacroDefinition(define.name, define.value);
		}

		(compiler, options, kind)
	}

	[Tracy.Profile]
	private Result<VkShaderModule> CreateRaw(Shaderc.CompilationResult result, StringView sourceName) {
		VkShaderModuleCreateInfo createInfo = .() {
			codeSize = result.SpvLength * 4,
			pCode = result.Spv
		};

		VkShaderModule module = ?;
		VkResult vkResult = vkCreateShaderModule(Gfx.Device, &createInfo, null, &module);

		if (vkResult != .VK_SUCCESS) {
			Log.Error("Failed to create shader module '{}': {}", sourceName, vkResult);
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_SHADER_MODULE,
				objectHandle = module,
				pObjectName = scope $"[SHADER] {sourceName}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}

		return module;
	}

	class Entry {
		private ShaderType type;
		private ShaderSource source ~ delete _;
		private RefCounted<ShaderPreProcessCallback> preProcessCallback ~ _?.Release();

		private uint8[64] sourceHash;
		public Shader shader ~ ReleaseAndNullify!(_);

		public this(ShaderType type, ShaderSource source, RefCounted<ShaderPreProcessCallback> preProcessCallback) {
			this.type = type;
			this.source = source.Copy();
			this.preProcessCallback = preProcessCallback != null ? preProcessCallback..AddRef() : null;
		}
		
		public Result<void> Reload(Info? info = null, bool force = false) {
			var info;

			// Return if this is an inline shader and the shader has already been created
			if (source.Type == .String && shader != null) return .Ok;

			// Create info if it was not passed in
			if (info == null) {
				ShaderPreProcessOptions preProcessor = scope:: .();
				preProcessCallback?.Value(preProcessor);

				info = Info.Point(type, source, preProcessor);
			}

			// Pre process
			String preProcessedSource = new .();
			String sourceName = new .();

			defer {
				delete preProcessedSource;
				delete sourceName;
			}

			Gfx.Shaders.PreProcess(info.Value, preProcessCallback, preProcessedSource, sourceName).GetOrPropagate!();

			// Return if this is a file shader and the contents have not changed
			if (source.Type == .File) {
				SHA512 sha = scope .();

				sha.Update(.((.) preProcessedSource.Ptr, preProcessedSource.Length)).GetOrPropagate!();
				uint8[64] sourceHash = sha.Final().GetOrPropagate!();

				if (!force && shader != null && this.sourceHash == sourceHash) {
					return .Ok;
				}

				this.sourceHash = sourceHash;
			}

			// Release previous shader
			ReleaseAndNullify!(shader);

			// Create
			shader = Gfx.Shaders.Create(info.Value, preProcessedSource, sourceName).GetOrPropagate!();
			
			return .Ok;
		}
	}

	struct Info : IEquatable<Self>, IHashable, IDisposable {
		public ShaderType type;
		public ShaderSource source;
		public Span<ShaderDefine> defines;

		private int hash;
		private bool copied;

		private this(ShaderType type, ShaderSource source, Span<ShaderDefine> defines, bool copied) {
			this.type = type;
			this.source = source;
			this.defines = defines;

			this.hash = Utils.CombineHashCode(Utils.CombineHashCode(type.Underlying, source.GetHashCode()), defines.GetCombinedHashCode());
			this.copied = copied;
		}

		public static Self Point(ShaderType type, ShaderSource source, ShaderPreProcessOptions preProcessor) => .(type, source, preProcessor != null ? preProcessor.Defines : .(), false);

		public static Self Copy(Self info) {
			Span<ShaderDefine> defines = .(new ShaderDefine[info.defines.Length]*, info.defines.Length);

			for (int i < defines.Length) {
				defines[i] = new .(info.defines[i]);
			}

			return .(info.type, info.source, defines, true);
		}

		public bool Equals(Self other) {
			if (type != other.type) return false;
			if (source != other.source) return false;
			if (defines.Length != other.defines.Length) return false;

			for (int i < defines.Length) {
				if (defines[i] != other.defines[i]) return false;
			}

			return true;
		}

		public int GetHashCode() => hash;

		public void Dispose() {
			if (copied) {
				for (let define in defines) {
					delete define;
				}

				delete defines.Ptr;
			}
		}

		// Idk why it did not mark the defines automatically
		protected override void GCMarkMembers() {
			for (let define in defines) {
				GC.Mark(define);
			}
		}

		[Commutable]
		public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	}
}