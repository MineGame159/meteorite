using System;

using static Meteorite.GL;

namespace Meteorite{
	class Framebuffer {
		private uint32 id;
		public uint32 depthTexture;

		public this() {
			glCreateFramebuffers(1, &id);

			glNamedFramebufferDrawBuffer(id, 0);
			glNamedFramebufferReadBuffer(id, 0);

			glCreateTextures(GL_TEXTURE_2D, 1, &depthTexture);
			glTextureParameteri(depthTexture, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			glTextureParameteri(depthTexture, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			glTextureParameteri(depthTexture, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
			glTextureParameteri(depthTexture, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
			float[4] borderColor = .(1.0f, 1.0f, 1.0f, 1.0f);
			glTextureParameterfv(depthTexture, GL_TEXTURE_BORDER_COLOR, &borderColor);
			glTextureStorage2D(depthTexture, 1, GL_DEPTH_COMPONENT16, 2048, 2048);

			glNamedFramebufferTexture(id, GL_DEPTH_ATTACHMENT, depthTexture, 0);
		}

		public void Bind() => glBindFramebuffer(GL_FRAMEBUFFER, id);
		public void Unbind() => glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}
}