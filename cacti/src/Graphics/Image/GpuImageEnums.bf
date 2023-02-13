using System;

using Bulkan;
using Bulkan.Utilities;

namespace Cacti.Graphics;

enum ImageFormat {
	case RGBA,
		 BGRA,
		 RGBA16,
		 RGBA32,
		 R8,
		 RG8,
		 Depth;

	public VkFormat Vk { get {
		switch (this) {
		case .RGBA:		return .VK_FORMAT_R8G8B8A8_UNORM;
		case .BGRA:		return .VK_FORMAT_B8G8R8A8_UNORM;
		case .RGBA16:	return .VK_FORMAT_R16G16B16A16_SFLOAT;
		case .RGBA32:	return .VK_FORMAT_R32G32B32A32_SFLOAT;
		case .R8:		return .VK_FORMAT_R8_UNORM;
		case .RG8:		return .VK_FORMAT_R8G8_UNORM;
		case .Depth:	return .VK_FORMAT_D32_SFLOAT;
		}
	} }

	public uint64 Bytes { get {
		switch (this) {
		case .RGBA, BGRA:	return 4;
		case .RGBA16:		return 8;
		case .RGBA32:		return 16;
		case .R8:			return 1;
		case .RG8:			return 2;
		case .Depth:		return 4;
		}
	} }
}

enum ImageUsage {
	case Normal,
		 ColorAttachment,
		 DepthAttachment;

	public VkImageUsageFlags Vk { get {
		switch (this) {
		case .Normal:			return .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		case .ColorAttachment:	return .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		case .DepthAttachment:	return .VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		}
	} }
}

enum ImageAccess {
	case Undefined,
		 ColorAttachment,
		 DepthAttachment,
		 Write,
		 Read,
		 Sample,
		 Present;

	public VkImageLayout Vk { get {
		switch (this) {
		case .Undefined:		return .VK_IMAGE_LAYOUT_UNDEFINED;
		case .ColorAttachment:	return .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
		case .DepthAttachment:	return .VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL;
		case .Write:			return .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		case .Read:				return .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
		case .Sample:			return .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		case .Present:			return .VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
		}
	} }

	public ThsvsAccessType Thsvs { get {
		switch (this) {
		case .Undefined:		return .THSVS_ACCESS_NONE;
		case .ColorAttachment:	return .THSVS_ACCESS_COLOR_ATTACHMENT_WRITE;
		case .DepthAttachment:	return .THSVS_ACCESS_DEPTH_ATTACHMENT_WRITE_STENCIL_READ_ONLY;
		case .Write:			return .THSVS_ACCESS_TRANSFER_WRITE;
		case .Read:				return .THSVS_ACCESS_TRANSFER_READ;
		case .Sample:			return .THSVS_ACCESS_FRAGMENT_SHADER_READ_SAMPLED_IMAGE_OR_UNIFORM_TEXEL_BUFFER;
		case .Present:			return .THSVS_ACCESS_PRESENT;
		}
	} }
}