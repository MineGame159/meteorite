using System;
using System.Interop;
using System.Collections;

namespace Cacti.Graphics;

class ShaderInfo : IEquatable<Self>, IEquatable, IHashable {
	private Dictionary<int, DescriptorType>[PipelineInfo.MAX_DESCRIPTOR_SETS] sets;
	private uint32 pushConstantSize;

	public Dictionary<int, DescriptorType>[PipelineInfo.MAX_DESCRIPTOR_SETS] Sets => sets;
	public uint32 PushConstantSize => pushConstantSize;

	public int SetCount { get {
		int count = 0;

		for (let set in sets) {
			if (set != null) count++;
		}

		return count;
	} }

	public this() {}

	public this(ShaderInfo info) {
		Merge(info);
	}

	public ~this() {
		for (let set in sets) {
			delete set;
		}
	}

	public void Clear() {
		for (var set in ref sets) {
			DeleteAndNullify!(set);
		}

		pushConstantSize = 0;
	}

	public Result<void> AddDescriptor(int setI, int location, DescriptorType type) {
		if (setI >= PipelineInfo.MAX_DESCRIPTOR_SETS) return .Err;

		// Get descriptor set
		if (setI >= sets.Count) {
			Log.Error("Failed to parse shader, maximum number of descriptor sets is {}", sets.Count);
			return .Err;
		}

		var set = ref sets[setI];
		if (set == null) set = new .();

		// Add descriptor
		DescriptorType prevType;

		if (set.TryGetValue(location, out prevType)) {
			if (prevType != type) {
				Log.Error("Failed to parse shader, tried to assign different descriptor types to the same location");
				return .Err;
			}
		}

		set[location] = type;

		return .Ok;
	}

	public Result<void> Merge(ShaderInfo other) {
		// Descriptors
		for (int i < sets.Count) {
			let otherSet = other.sets[i];
			if (otherSet == null) continue;

			var set = ref sets[i];
			if (set == null) set = new .();

			// Check if overlapping descriptors match and add missing ones
			for (let (location, otherType) in otherSet) {
				DescriptorType type;

				if (set.TryGetValue(location, out type)) {
					if (type != otherType) {
						Log.Error("Failed to parse shader, descriptor bindings need to match between all shaders in a pipeline");
						return .Err;
					}
				}
				else {
					set[location] = otherType;
				}
			}
		}

		// Push constant
		if (pushConstantSize == 0) {
			pushConstantSize = other.pushConstantSize;
		}
		else if (other.pushConstantSize != 0 && pushConstantSize != other.pushConstantSize) {
			Log.Error("Failed to parse shader, push constant blocks need to match between all shaders in a pipeline");
			return .Err;
		}

		return .Ok;
	}

	public mixin GetSet(int i) {
		let set = sets[i];
		DescriptorType[] types;

		if (set == null) {
			types = scope:mixin .[0];
		}
		else {
			types = scope:mixin .[set.Count];

			for (let (location, type) in set) {
				types[location] = type;
			}
		}

		types
	}

	public bool Equals(Self other) {
		if (pushConstantSize != other.pushConstantSize) return false;

		for (int i < sets.Count) {
			let set1 = sets[i];
			let set2 = other.sets[i];

			if (set1.Count != set2.Count) return false;

			for (let (location, type) in set1) {
				DescriptorType otherType;

				if (set2.TryGetValue(location, out otherType)) {
					if (type != otherType) return false;
				}
				else {
					return false;
				}
			}
		}

		return true;
	}

	public bool Equals(Object other) {
		return (other is Self) ? Equals((Self) other) : false;
	}

	public int GetHashCode() {
		int hash = Utils.CombineHashCode(pushConstantSize, sets.Count);

		for (let set in sets) {
			if (set == null) continue;

			for (let (location, type) in set) {
				Utils.CombineHashCode(ref hash, location);
				Utils.CombineHashCode(ref hash, type);
			}
		}

		return hash;
	}
}

class ShaderReflect {
	private Module* module = new .();

	public Result<void> Create(void* code, uint size) {
		uint result = spvReflectCreateShaderModule(size, code, module);
		if (result != 0) return .Err;

		return .Ok;
	}

	public ~this() {
		spvReflectDestroyShaderModule(module);
		delete module;
	}

	public Result<void> Get(ShaderInfo info) {
		// Descriptors
		uint32 count = 0;
		if (spvReflectEnumerateDescriptorBindings(module, &count, null) != 0) return .Err;

		BumpAllocator alloc = scope .(); // Simply using new:ScopedAlloc! results in memory leaks because why not
		DescriptorBinding** descriptors = count > 0 ? new:alloc .[count]* : null;

		if (spvReflectEnumerateDescriptorBindings(module, &count, descriptors) != 0) return .Err;

		for (int i < count) {
			DescriptorBinding* descriptor = descriptors[i];
			DescriptorType type;

			switch (descriptor.Type) {
			case .UNIFORM_BUFFER:			type = .UniformBuffer;
			case .STORAGE_BUFFER:			type = .StorageBuffer;
			case .COMBINED_IMAGE_SAMPLER:	type = .SampledImage;
			default:
				Log.Error("Failed to parse shader, invalid descriptor type: {}", descriptor.Type);
				return .Err;
			}

			info.AddDescriptor(descriptor.Set, descriptor.Binding, type).GetOrPropagate!();
		}

		// Push constant
		count = 0;
		if (spvReflectEnumeratePushConstantBlocks(module, &count, null) != 0) return .Err;

		if (count > 1) {
			Log.Error("Failed to parse shader, there can only be a single push constant block");
			return .Err;
		}

		PushConstant* pushConstant = new:alloc .();
		if (spvReflectEnumeratePushConstantBlocks(module, &count, &pushConstant) != 0) {
			return .Err;
		}

		if (pushConstant.Offset != 0) {
			Log.Error("Failed to parse shader, push constants need to have an offset of 0");
			return .Err;
		}

		info.[Friend]pushConstantSize = pushConstant.Size;

		// Return
		return .Ok;
	}

	// Bindings

	[CRepr]
	struct Module {
		private uint8[1200] _;
	}

	enum SpvReflectDescriptorType : c_uint {
	  SAMPLER                    =  0,
	  COMBINED_IMAGE_SAMPLER     =  1,
	  SAMPLED_IMAGE              =  2,
	  STORAGE_IMAGE              =  3,
	  UNIFORM_TEXEL_BUFFER       =  4,
	  STORAGE_TEXEL_BUFFER       =  5,
	  UNIFORM_BUFFER             =  6,
	  STORAGE_BUFFER             =  7,
	  UNIFORM_BUFFER_DYNAMIC     =  8,
	  STORAGE_BUFFER_DYNAMIC     =  9,
	  INPUT_ATTACHMENT           = 10,
	  ACCELERATION_STRUCTURE_KHR = 1000150000
	}

	[CRepr]
	struct DescriptorBinding {
		private uint8[600] _;

		public uint32 Set mut => *(uint32*) &_[24];
		public uint32 Binding mut => *(uint32*) &_[16];
		public SpvReflectDescriptorType Type mut => *(SpvReflectDescriptorType*) &_[28];
	}

	[CRepr]
	struct PushConstant {
		private uint8[360] _;

		public uint32 Offset mut => *(uint32*) &_[16];
		public uint32 Size mut => *(uint32*) &_[24];
	}

	[CLink]
	private static extern c_uint spvReflectCreateShaderModule(c_size size, void* code, Module* module);
	
	[CLink]
	private static extern void spvReflectDestroyShaderModule(Module* module);

	[CLink]
	private static extern c_uint spvReflectEnumerateDescriptorBindings(Module* module, uint32* count, DescriptorBinding** bindings);

	[CLink]
	private static extern c_uint spvReflectEnumeratePushConstantBlocks(Module* module, uint32* count, PushConstant** pushConstants);
}