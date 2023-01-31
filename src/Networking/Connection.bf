using System;
using System.Net;
using System.Threading;
using System.Collections;

using Cacti;
using Cacti.Crypto;

using MiniZ;

namespace Meteorite {
	abstract class Connection {
		private const int32 S2C_SET_COMPRESSION = 0x03;

		public StringView ip;
		public int32 port;
		public bool closed;

		private Socket s ~ delete _;
		private Thread t ~ delete _;

		private int neededLength;
		private int compressionThreshold = -1;

		private AES aesEncrypt ~ delete _;
		private AES aesDecrypt ~ delete _;

		public this(StringView ip, int32 port) {
			this.ip = ip;
			this.port = port;
		}

		public ~this() {
			Log.Info("Disconnecting");

			s.Close();
			t?.Join();
		}

		public void EnableCompression(uint8[16] sharedSecret) {
			aesEncrypt = new .();
			aesEncrypt.SetKey(sharedSecret, sharedSecret, .Encrypt);

			aesDecrypt = new .();
			aesDecrypt.SetKey(sharedSecret, sharedSecret, .Encrypt);
		}

		protected void Start() {
			Socket.Init();

			s = new .();
			s.Blocking = false;

			if (s.Connect(ip, port) case .Ok) {
				Log.Info("Connected to {}:{}", ip, port);

				neededLength = -1;

				t = new Thread(new => Receive);
				t.SetName("Networking");
				t.Start(false);

				OnReady();
			}
			else {
				Log.Error("Failed to connect to {}:{}", ip, port);
				closed = true;
			}
		}

		protected abstract void OnReady();

		protected abstract void OnConnectionLost();

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

					if (aesEncrypt != null) Decrypt(buf, received);

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
							MiniZ.ReturnStatus status = MiniZ.Uncompress(packet.data, ref uncompressedLength, &buffer.data[buffer.pos], (.) (neededLength + lengthSize - buffer.pos));
							packet.size = uncompressedLength;

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

			let result = Send(packet.[Friend]data, packet.size);
			if (result == .Err) OnConnectionLost();
		}

		private Result<int> Send(uint8* data, int size) {
			uint8* toSend = data;

			if (aesEncrypt != null) {
				uint8* encrypted = new .[size]*;
				defer:: delete encrypted;

				aesEncrypt.EncryptCfb8(.(toSend, size), encrypted);
				toSend = encrypted;
			}

			return s.Send(toSend, size);
		}

		private void Decrypt(uint8* data, int size) {
			uint8* decrypted = new:ScopedAlloc! .[size]*;

			aesDecrypt.DecryptCfb8(.(data, size), decrypted);
			Internal.MemCpy(data, decrypted, size);
		}
	}
}