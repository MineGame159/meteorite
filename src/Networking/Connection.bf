using System;
using System.Net;
using System.Threading;
using System.Collections;

namespace Meteorite {
	abstract class Connection {
		private const int32 S2C_SET_COMPRESSION = 0x03;

		public StringView address;
		public int32 port;

		private Socket s ~ delete _;
		private Thread t ~ delete _;

		private int neededLength;
		private int compressionThreshold = -1;

		public this(StringView address, int32 port) {
			this.address = address;
			this.port = port;

			Socket.Init();

			s = new .();
			s.Blocking = false;

			if (s.Connect(address, port) case .Ok) Log.Info("Connected to {}:{}", address, port);
			else Log.Error("Failed to connect to {}:{}", address, port);

			neededLength = -1;

			t = new Thread(new => Receive);
			t.SetName("Networking");
			t.Start(false);

			OnReady();
		}

		public ~this() {
			Log.Info("Disconnecting");

			s.Close();
			t.Join();
		}

		protected abstract void OnReady();

		protected abstract void OnPacket(int id, NetBuffer packet);

		private void BeforeOnPacket(int id, NetBuffer packet) {
			if (id == S2C_SET_COMPRESSION) compressionThreshold = packet.ReadVarInt();
			else OnPacket(id, packet);
		}

		private void Receive() {
			Socket.FDSet set = .();
			set.Add(s.NativeSocket);

			uint8* buf = new uint8[1024]*;
			NetBuffer buffer = scope .(8192);

			for (;;) {
				Socket.Select(&set, null, null, 1000);

				if (set.IsSet(s.NativeSocket)) {
					int received = 0;

					if (s.Recv(buf, 1024) case .Ok(let v)) received = v;
					else break;

					buffer.Write(buf, received);

					if (neededLength == -1) neededLength = buffer.ReadVarInt();

					while (buffer.HasEnough(neededLength)) {
						int lengthSize = buffer.pos;

						int uncompressedLength = -1;

						if (compressionThreshold >= 0) {
						    int a = buffer.ReadVarInt();
						    if (a > 0) uncompressedLength = a;
						}

						if (uncompressedLength != -1) {
							NetBuffer packet = scope .(uncompressedLength);
							uint uLength = (.) uncompressedLength;
							MiniZ.ReturnStatus status = MiniZ.mz_uncompress(packet.data, &uLength, &buffer.data[buffer.pos], (.) (neededLength + lengthSize - buffer.pos));
							packet.size = (.) uLength;

							if (status == .OK) {
								int id = packet.ReadVarInt();
								BeforeOnPacket(id, packet);
							}
							else Log.Error("Failed to uncompress packet with status {}", status);
						}
						else {
							int id = buffer.ReadVarInt();
							BeforeOnPacket(id, buffer);
						}

						buffer.MoveToStart(lengthSize + neededLength);

						neededLength = -1;
						if (buffer.size > 4) neededLength = buffer.ReadVarInt();
					}
				}

				set.Add(s.NativeSocket);
			}

			delete buf;
		}

		public void Send(NetBuffer buffer) {
			int uncompressedLengthSize = 0;
			if (compressionThreshold != -1) uncompressedLengthSize = NetBuffer.GetVarIntSize(0);

			int size = NetBuffer.GetVarIntSize((.) buffer.size) + uncompressedLengthSize + buffer.size;

			NetBuffer packet = scope .(size);

			packet.WriteVarInt((.) (buffer.size + uncompressedLengthSize));
			if (compressionThreshold != -1) packet.WriteVarInt(0);
			packet.Write(buffer);

			s.Send(packet.[Friend]data, packet.size);
		}
	}
}