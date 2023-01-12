using System;
using System.Threading;
using System.Diagnostics;
using System.Collections;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti {
	abstract class Application {
		public Window window ~ delete _;

		public TimeSpan lastFrameTime;

		public this(StringView title) {
			Log.AddLogger(new ConsoleLogger());

			window = new .(title);

			ImGuiCacti.Init(window);
		}

		public ~this() {
			ImGuiCacti.Destroy();
			Gfx.Destroy();
		}

		private bool stop = false;

		public void Run() {
			Stopwatch sw = scope .(true);

			VkSemaphoreCreateInfo semaphoreInfo = .();
			VkSemaphore imageAvailableSemaphore = ?;
			VkSemaphore renderFinishedSemaphore = ?;

			vkCreateSemaphore(Gfx.Device, &semaphoreInfo, null, &imageAvailableSemaphore);
			vkCreateSemaphore(Gfx.Device, &semaphoreInfo, null, &renderFinishedSemaphore);

			VkFenceCreateInfo fenceInfo = .() {
				flags = .VK_FENCE_CREATE_SIGNALED_BIT
			};
			VkFence inFlightFence = ?;

			vkCreateFence(Gfx.Device, &fenceInfo, null, &inFlightFence);

			TimeSpan lastTime = sw.Elapsed;

			while (window.Open) {
				// Calculate delta
				TimeSpan time = sw.Elapsed;
				double delta = (time - lastTime).TotalSeconds;
				lastTime = time;

				// Poll events and call Update
				window.PollEvents();
				Update(delta);

				if (!window.minimized && !stop) {
					// GPU Synchronization
					vkWaitForFences(Gfx.Device, 1, &inFlightFence, true, uint64.MaxValue);
					vkResetFences(Gfx.Device, 1, &inFlightFence);
	
					GpuImage target = GetTargetImage(imageAvailableSemaphore);
					GpuImage present = GetPresentImage();

					TimeSpan frameStart = sw.Elapsed;
	
					// Call NewFrame and Render
					Gfx.NewFrame();
					List<CommandBuffer> commandBuffers = Render(.. scope .(), target, delta);

					// Uploads
					CommandBuffer uploadCmds = Gfx.Uploads.BuildCommandBuffer();
					if (uploadCmds != null) commandBuffers.Add(uploadCmds);

					// ImGui
					CommandBuffer imguiCmds = ImGuiCacti.Render(target);
					if (imguiCmds != null) commandBuffers.Add(imguiCmds);

					// After render
					CommandBuffer afterCmds = AfterRender(target);
					if (afterCmds != null) commandBuffers.Add(afterCmds);

					// Transition target to Present if needed
					if (present.Access != .Present) {
						CommandBuffer cmds = Gfx.CommandBuffers.GetBuffer();
						cmds.Begin();

						cmds.TransitionImage(present, .Present);

						cmds.End();
						commandBuffers.Add(cmds);
					}
	
					// Submit
					VkCommandBuffer[] rawCommandBuffers = scope .[commandBuffers.Count];
					for (let commandBuffer in commandBuffers) rawCommandBuffers[@commandBuffer.Index] = commandBuffer.[Friend]handle;
	
					VkPipelineStageFlags waitStage = .VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
					VkSubmitInfo submitInfo = .() {
						waitSemaphoreCount = 1,
						pWaitSemaphores = &imageAvailableSemaphore,
						pWaitDstStageMask = &waitStage,
						commandBufferCount = (.) rawCommandBuffers.Count,
						pCommandBuffers = rawCommandBuffers.Ptr,
						signalSemaphoreCount = 1,
						pSignalSemaphores = &renderFinishedSemaphore
					};
	
					vkQueueSubmit(Gfx.GraphicsQueue, 1, &submitInfo, inFlightFence);

					// Calculate frame time
					TimeSpan frameEnd = sw.Elapsed;
					lastFrameTime = frameEnd - frameStart;
	
					// Present
					VkPresentInfoKHR presentInfo = .() {
						waitSemaphoreCount = 1,
						pWaitSemaphores = &renderFinishedSemaphore,
						swapchainCount = 1,
						pSwapchains = &Gfx.Swapchain.[Friend]handle,
						pImageIndices = &Gfx.Swapchain.index
					};

					vkQueuePresentKHR(Gfx.PresentQueue, &presentInfo);
				}

				// Sleep if the window is minimized
				if (window.minimized) Thread.Sleep(1);
			}

			vkDeviceWaitIdle(Gfx.Device);
		}

		protected abstract void Update(double delta);

		protected abstract void Render(List<CommandBuffer> commandBuffers, GpuImage target, double delta);

		protected virtual CommandBuffer AfterRender(GpuImage target) {
			return null;
		}



		private GpuImage swapchainImage;

		protected virtual GpuImage GetTargetImage(VkSemaphore imageAvailableSemaphore) {
			return swapchainImage = Gfx.Swapchain.GetImage(imageAvailableSemaphore);
		}

		protected virtual GpuImage GetPresentImage() => swapchainImage;
	}
}