using System;

namespace Meteorite {
	enum PacketRequires {
		Nothing,
		World,
		Player
	}

	abstract class Packet {
		public int32 id;

		protected Meteorite me;

		public this(int32 id) {
			this.id = id;
			this.me = Meteorite.INSTANCE;
		}
	}

	abstract class S2CPacket : Packet {
		public PacketRequires requires;

		public this(int32 id, PacketRequires requires = .Nothing) : base(id) {
			this.requires = requires;
		}

		public abstract void Read(NetBuffer buf);
	}

	abstract class C2SPacket : Packet {
		public this(int32 id) : base(id) {}

		public virtual int DefaultBufferSize => 64;

		public abstract void Write(NetBuffer buf);
	}
}