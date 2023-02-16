using System;

using Bulkan;

namespace Cacti.Graphics;

enum Primitive {
	case Traingles,
		 Lines,
		 Points;
	
	public VkPrimitiveTopology Vk { get {
		switch (this) {
		case .Traingles:	return .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
		case .Lines:		return .VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
		case .Points:		return .VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
		}
	} }
}

enum PolygonMode {
	case Fill,
		 Line,
		 Point;
	
	public VkPolygonMode Vk { get {
		switch (this) {
		case .Fill:		return .VK_POLYGON_MODE_FILL;
		case .Line:		return .VK_POLYGON_MODE_LINE;
		case .Point:	return .VK_POLYGON_MODE_POINT;
		}
	} }
}

enum CullMode {
	case None,
		 Front,
		 Back;
	
	public VkCullModeFlags Vk { get {
		switch (this) {
		case .None:		return .VK_CULL_MODE_NONE;
		case .Front:	return .VK_CULL_MODE_FRONT_BIT;
		case .Back:		return .VK_CULL_MODE_BACK_BIT;
		}
	} }
}

enum FrontFace {
	case Clockwise,
		 CounterClockwise;
	
	public VkFrontFace Vk { get {
		switch (this) {
		case .Clockwise:		return .VK_FRONT_FACE_CLOCKWISE;
		case .CounterClockwise:	return .VK_FRONT_FACE_COUNTER_CLOCKWISE;
		}
	} }
}

enum BlendOp {
	case Add;

	public VkBlendOp Vk { get {
		return .VK_BLEND_OP_ADD;
	} }
}

enum BlendFactor {
	case SrcAlpha,
		 OneMinusSrcAlpha,
		 OneMinusDstAlpha,
		 OneMinusSrcColor,
		 OneMinusDstColor,
		 One,
		 Zero;

	public VkBlendFactor Vk { get {
		switch (this) {
		case .SrcAlpha:			return .VK_BLEND_FACTOR_SRC_ALPHA;
		case .OneMinusSrcAlpha:	return .VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
		case .OneMinusDstAlpha:	return .VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
		case .OneMinusSrcColor:	return .VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
		case .OneMinusDstColor:	return .VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
		case .One:				return .VK_BLEND_FACTOR_ONE;
		case .Zero:				return .VK_BLEND_FACTOR_ZERO;
		}
	} }
}

struct BlendMode : this(BlendOp op, BlendFactor src, BlendFactor dst) {}

struct Blending {
	public bool enabled;
	public BlendMode color, alpha;

	private this(bool enabled, BlendMode color, BlendMode alpha) {
		this.enabled = enabled;
		this.color = color;
		this.alpha = alpha;
	}

	public static Self Disabled() => .(false, default, default);

	public static Self Enabled(BlendMode color, BlendMode alpha) => .(true, color, alpha);

	public static Self Default() => .(true, .(.Add, .SrcAlpha, .OneMinusSrcAlpha), .(.Add, .One, .Zero));
}

struct PipelineTarget : this(ImageFormat format, Blending blending) {}