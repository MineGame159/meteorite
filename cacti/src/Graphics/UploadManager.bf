using System;
using System.Collections;

namespace Cacti.Graphics;

class UploadManager {
	private const int MAX_FRAME_ALLOCATOR_SIZE = 1024 * 1024; // 1 kB

	private List<BufferUpload> bufferUploads = new .() ~ DeleteContainerAndDisposeItems!(_);
	private List<ImageUpload> imageUploads = new .() ~ DeleteContainerAndDisposeItems!(_);

	[Tracy.Profile]
	public void UploadBuffer(GpuBufferView dst, void* data, uint64 size, delegate void() callback = null, bool deleteCallback = true) {
		let (src, deleteSrc) = UploadSrc(data, size);

		bufferUploads.Add(.(src, dst, callback, deleteSrc, deleteCallback));
	}
	
	[Tracy.Profile]
	public void UploadImage(GpuImage dst, void* data, int mipLevel = 0, delegate void() callback = null, bool deleteCallback = true) {
		let (src, deleteSrc) = UploadSrc(data, dst.GetByteSize(mipLevel));

		imageUploads.Add(.(src, dst, mipLevel, callback, deleteSrc, deleteCallback));
	}

	private (GpuBufferView, bool) UploadSrc(void* data, uint64 size) {
		GpuBufferView src;
		bool deleteSrc;

		if (size <= MAX_FRAME_ALLOCATOR_SIZE) {
			src = Gfx.FrameAllocator.Allocate(.None, size);
			deleteSrc = false;
		}
		else {
			src = Gfx.Buffers.Create(scope $"Upload: {size}", .None, .Mappable | .TransferSrc, size).Value;
			deleteSrc = true;
		}

		src.Upload(data, size);

		return (src, deleteSrc);
	}

	[Tracy.Profile]
	public void NewFrame() {
		// Buffers
		for (let upload in bufferUploads) {
			if (upload.callback != null) {
				upload.callback();
			}

			upload.Dispose();
		}

		bufferUploads.Clear();

		// Images
		for (let upload in imageUploads) {
			if (upload.callback != null) {
				upload.callback();
			}

			upload.Dispose();
		}

		imageUploads.Clear();
	}

	[Tracy.Profile]
	public CommandBuffer BuildCommandBuffer() {
		if (bufferUploads.IsEmpty && imageUploads.IsEmpty) return null;

		CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
		cmds.Begin();
		cmds.PushDebugGroup("Uploads");

		// Buffers
		for (let upload in bufferUploads) {
			cmds.CopyBufferToBuffer(upload.src, upload.dst, upload.src.size);
		}

		// Images
		for (let upload in imageUploads) {
			cmds.CopyBufferToImage(upload.src, upload.dst, upload.mipLevel);
		}

		cmds.PopDebugGroup();
		cmds.End();

		return cmds;
	}

	struct BufferUpload : this(GpuBufferView src, GpuBufferView dst, delegate void() callback, bool deleteSrc, bool deleteCallback), IDisposable {
		public void Dispose() {
			if (deleteSrc) src.buffer.Release();
			if (deleteCallback) delete callback;
		}
	}

	struct ImageUpload : this(GpuBufferView src, GpuImage dst, int mipLevel, delegate void() callback, bool deleteSrc, bool deleteCallback), IDisposable {
		public void Dispose() {
			if (deleteSrc) src.buffer.Release();
			if (deleteCallback) delete callback;
		}
	}
}