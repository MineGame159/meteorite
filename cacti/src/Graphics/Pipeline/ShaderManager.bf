using System;
using System.IO;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

using Shaderc;

namespace Cacti.Graphics;

typealias ShaderReadResult = Shaderc.IncludeResult;
typealias ShaderReadCallback = delegate ShaderReadResult*(StringView path);

class ShaderManager {
	private Shaderc.CompileOptions options = new .() ~ delete _;
	private ShaderReadCallback readCallback ~ delete _;

	public this() {
		// Setup compiler options
#if DEBUG
		options.SetGenerateDebugInfo();
		options.SetOptimizationLevel(.Zero);
#elif RELEASE
		options.SetOptimizationLevel(.Performance);
#endif

		// Setup read callback
		readCallback = new (path) => {
			String buffer = scope .();
			let result = File.ReadAllText(path, buffer);

			switch (result) {
			case .Ok:	return ShaderReadResult.New(path, buffer);
			case .Err:	return ShaderReadResult.New("", "");
			}
		};
		
		// Setup include callback
		options.SetIncludeCallbacks(
			new (userData, requestedSource, type, requestingSource, includeDepth) => {
				String path = scope .();

				if (type == .Standard) Path.InternalCombine(path, requestedSource);
				else {
					String dir = scope .();
					Path.GetDirectoryPath(requestingSource, dir);

					Path.InternalCombine(path, dir, requestedSource);
				}
				
				return readCallback(path);
			},
			new (userData, includeResult) => {
				includeResult.Dispose();
			}
		);
	}

	public void SetReadCallback(ShaderReadCallback callback) {
		delete this.readCallback;
		this.readCallback = callback;
	}

	[Tracy.Profile]
	public Result<Shader> Create(ShaderType type, ShaderSource source, RefCounted<ShaderPreProcessCallback> prePreprocessCallback = null) {
		let (handle, result) = CreateRaw(type, source, prePreprocessCallback?.Value).GetOrPropagate!();
		defer delete result;

		Shader shader = new [Friend].(handle, type, source, prePreprocessCallback);

		if (shader.[Friend]Reflect(result.SpvLength * 4, result.Spv) == .Err) {
			delete shader;
			return .Err;
		}

		return shader;
	}

	private Result<(VkShaderModule, Shaderc.CompilationResult)> CreateRaw(ShaderType type, ShaderSource source, ShaderPreProcessCallback prePreprocessCallback) {
		// Get actual shader code
		StringView string;
		StringView inputFile;

		ShaderReadResult* sresult = null;

		switch (source.Type) {
		case .String:
			string = source.String;
			inputFile = "";

		case .File:
			sresult = readCallback(source.String);

			if (sresult.contentLength == 0) {
				Log.Error("Failed to read shader file: {}", source.String);
				sresult?.Dispose();
				return .Err;
			}

			string = .(sresult.content, (.) sresult.contentLength);
			inputFile = .(sresult.sourceName, (.) sresult.sourceNameLength);
		}

		// Create compiler
		Shaderc.Compiler compiler = scope .();
		Shaderc.CompileOptions options = scope .(options);

		switch (type) {
		case .Vertex:	options.AddMacroDefinition("VERTEX", "TRUE");
		case .Fragment:	options.AddMacroDefinition("FRAGMENT", "TRUE");
		}

		prePreprocessCallback?.Invoke([Friend].(options));
		
		// Compile
		Shaderc.CompilationResult result = compiler.CompileIntoSpv(string, type == .Vertex ? .Vertex : .Fragment, inputFile, "main", options);

		if (result.Status != .Success) {
			Log.Error("Failed to compile shader: {}", result.ErrorMessage);
			sresult?.Dispose();
			return .Err;
		}

		// Create Vulkan object
		VkShaderModuleCreateInfo info = .() {
			codeSize = result.SpvLength * 4,
			pCode = result.Spv
		};

		VkShaderModule module = ?;
		VkResult vkResult = vkCreateShaderModule(Gfx.Device, &info, null, &module);

		if (vkResult != .VK_SUCCESS) {
			Log.Error("Failed to create shader module '{}': {}", inputFile, vkResult);
			sresult?.Dispose();
			return .Err;
		}

		if (Gfx.DebugUtilsExt) {
			VkDebugUtilsObjectNameInfoEXT nameInfo = .() {
				objectType = .VK_OBJECT_TYPE_SHADER_MODULE,
				objectHandle = module,
				pObjectName = scope $"[SHADER] {(source.Type == .File ? inputFile : "<inline>")}"
			};
			vkSetDebugUtilsObjectNameEXT(Gfx.Device, &nameInfo);
		}
		
		sresult?.Dispose();
		return (module, result);
	}
}