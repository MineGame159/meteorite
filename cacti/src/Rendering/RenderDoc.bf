using System;
using System.Interop;

namespace Cacti {
	struct RenderDocApi {
		public void* GetApiVersion;

		public void* SetCaptureOptionU32;
		public void* SetCaptureOptionF32;

		public void* SetFocusToggleKeys;
		public void* SetCaptureKeys;

		public void* GetOverlayBits;
		public void* MaskOverlayBits;

		public void* RemoveHooks;
		public void* UnloadCrashHandler;

		public void* SetCaptureFilePathTemplate;
		public void* GetCaptureFilePathTemplate;

		public void* IsTargetControlConnected;
		public void* LaunchReplayUI;

		public void* SetActiveWindow;

		public function void(void* device, void* wndHandle) StartFrameCapture;
		public function uint32() IsFrameCapturing;
		public function uint32(void* device, void* wndHandle) EndFrameCapture;

		public void* TriggerMultiFrameCapture;

		public void* SetCaptureFileComments;

		public void* DiscardFrameCapture;

		public void* ShowReplayUI;
	}

	class RenderDoc {
		public static bool Loaded = false;

		typealias GetAPI = function c_int(c_int version, void** outAPIPointers);
		public static RenderDocApi* Api;

		public static void Init() {
#if BF_PLATFORM_WINDOWS
			Internal.LoadSharedLibrary("renderdoc");

			Windows.HModule module = Windows.GetModuleHandleA("renderdoc.dll");
			if (module.IsInvalid) return;

			GetAPI getApi = (.) Windows.GetProcAddress(module, "RENDERDOC_GetAPI");
			getApi(10500, (.) &Api);

			Loaded = true;
#endif
		}
	}
}