using System;

using static Meteorite.GL;

namespace Meteorite {
	enum VertexAttributeTypea {
		case UByte;
		case UShort;
		case UInt;
		case Float;

		public int Size { get {
			switch (this) {
			case .UByte:  return sizeof(uint8);
			case .UShort: return sizeof(uint16);
			case .UInt:   return sizeof(uint32);
			case .Float:  return sizeof(float);
			default:      return 0;
			}
		} }
	}

	struct VertexAttributea {
		public VertexAttributeTypea type;
		public int count;
		public bool normalized;

		public this(VertexAttributeTypea type, int count, bool normalized = false) {
			this.type = type;
			this.count = count;
			this.normalized = normalized;
		}

		public int Size => type.Size * count;
		public bool IsInteger => type != .Float;

		public uint OpenGlType { get {
			if (type == .UByte) return GL_UNSIGNED_BYTE;
			return type == .UInt ? GL_UNSIGNED_INT : GL_FLOAT;
		} }
	}

	class VertexFormat {
		public VertexAttributea[] attributes ~ delete _;
		public int stride;

		public this(params VertexAttributea[] attributes) {
			this.attributes = new VertexAttributea[attributes.Count];
			Array.Copy(attributes, this.attributes, attributes.Count);

			stride = 0;
			for (let attribute in attributes) stride += attribute.Size;
		}

		public void Apply(uint32 vao) {
			int offset = 0;

			for (int i < attributes.Count) {
				VertexAttributea attrib = attributes[i];

				glEnableVertexArrayAttrib(vao, (.) i);
				glVertexArrayAttribFormat(vao, (.) i, attrib.count, attrib.OpenGlType, attrib.normalized ? 1 : 0, (.) offset);
				glVertexArrayAttribBinding(vao, (.) i, 0);

				offset += attrib.Size;
			}
		}
	}
}