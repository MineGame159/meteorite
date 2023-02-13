using System;

using Bulkan;

namespace Cacti.Graphics;

enum GpuBufferType {
	case None,
		 Vertex,
		 Index,
		 Uniform,
		 Storage;

	public VkBufferUsageFlags Vk { get {
		switch (this) {
		case .None:		return .None;
		case .Vertex:	return .VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
		case .Index:	return .VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
		case .Uniform:	return .VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
		case .Storage:	return .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
		}
	} }

	public char8 Char { get {
		switch (this) {
		case .None:		return 'N';
		case .Vertex:	return 'V';
		case .Index:	return 'I';
		case .Uniform:	return 'U';
		case .Storage:	return 'S';
		}
	} }
}

enum GpuBufferUsage {
	case None = 0,
		 Mappable = 1,
		 TransferSrc = 2,
		 TransferDst = 4,
		 Dedicated = 8;
}