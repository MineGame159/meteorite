using System;
using System.Collections;

using Bulkan;

namespace Cacti;

enum GVertexAttributeType {
	case Float,
		 I8,
		 U8,
		 I16,
		 U16,
		 I32,
		 U32;

	public int Size { get {
		switch (this) {
		case .Float:	return 4;
		case .I8, U8:	return 1;
		case .I16, U16:	return 2;
		case .I32, U32:	return 4;
		}
	} }
}

struct GVertexAttribute : this(GVertexAttributeType type, int count, bool normalized) {
	public int Size => type.Size * count;

	public VkFormat VkFormat { get {
		switch (type) {
		case .Float:
			if (normalized) Runtime.FatalError(scope $"{type} cannot be normalized");

			switch (count) {
			case 1: return .VK_FORMAT_R32_SFLOAT;
			case 2: return .VK_FORMAT_R32G32_SFLOAT;
			case 3: return .VK_FORMAT_R32G32B32_SFLOAT;
			case 4: return .VK_FORMAT_R32G32B32A32_SFLOAT;
			}
		case .I8:
			switch (count) {
			case 1: return normalized ? .VK_FORMAT_R8_SNORM : .VK_FORMAT_R8_SINT;
			case 2: return normalized ? .VK_FORMAT_R8G8_SNORM : .VK_FORMAT_R8G8_SINT;
			case 3: return normalized ? .VK_FORMAT_R8G8B8_SNORM : .VK_FORMAT_R8G8B8_SINT;
			case 4: return normalized ? .VK_FORMAT_R8G8B8A8_SNORM : .VK_FORMAT_R8G8B8A8_SINT;
			}
		case .U8:
			switch (count) {
			case 1: return normalized ? .VK_FORMAT_R8_UNORM : .VK_FORMAT_R8_UINT;
			case 2: return normalized ? .VK_FORMAT_R8G8_UNORM : .VK_FORMAT_R8G8_UINT;
			case 3: return normalized ? .VK_FORMAT_R8G8B8_UNORM : .VK_FORMAT_R8G8B8_UINT;
			case 4: return normalized ? .VK_FORMAT_R8G8B8A8_UNORM : .VK_FORMAT_R8G8B8A8_UINT;
			}
		case .I16:
			switch (count) {
			case 1:	return normalized ? .VK_FORMAT_R16_SNORM : .VK_FORMAT_R16_SINT;
			case 2:	return normalized ? .VK_FORMAT_R16G16_SNORM : .VK_FORMAT_R16G16_SINT;
			case 3:	return normalized ? .VK_FORMAT_R16G16B16_SNORM : .VK_FORMAT_R16G16B16_SINT;
			case 4:	return normalized ? .VK_FORMAT_R16G16B16A16_SNORM : .VK_FORMAT_R16G16B16A16_SINT;
			}
		case .U16:
			switch (count) {
			case 1:	return normalized ? .VK_FORMAT_R16_UNORM : .VK_FORMAT_R16_UINT;
			case 2:	return normalized ? .VK_FORMAT_R16G16_UNORM : .VK_FORMAT_R16G16_UINT;
			case 3:	return normalized ? .VK_FORMAT_R16G16B16_UNORM : .VK_FORMAT_R16G16B16_UINT;
			case 4:	return normalized ? .VK_FORMAT_R16G16B16A16_UNORM : .VK_FORMAT_R16G16B16A16_UINT;
			}
		case .I32:
			switch (count) {
			case 1: return .VK_FORMAT_R32_SINT;
			case 2: return .VK_FORMAT_R32G32_SINT;
			case 3: return .VK_FORMAT_R32G32B32_SINT;
			case 4: return .VK_FORMAT_R32G32B32A32_SINT;
			}
		case .U32:
			switch (count) {
			case 1: return .VK_FORMAT_R32_UINT;
			case 2: return .VK_FORMAT_R32G32_UINT;
			case 3: return .VK_FORMAT_R32G32B32_UINT;
			case 4: return .VK_FORMAT_R32G32B32A32_UINT;
			}
		}

		Runtime.FatalError(scope $"Unknown vertex attribute combination: Type: {type}, Count: {count}, Normalized: {normalized}");
	} }
}

class VertexFormat {
	public List<GVertexAttribute> attributes = new .() ~ delete _;
	public int size;
	
	public Self Attribute(GVertexAttributeType type, int count, bool normalized = false) {
		GVertexAttribute attribute = .(type, count, normalized);

		attributes.Add(attribute);
		size += attribute.Size;

		return this;
	}
}