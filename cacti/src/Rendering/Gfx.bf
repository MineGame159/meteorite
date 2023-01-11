using System;
using System.Collections;

using GLFW;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti;

static class Gfx {
	public static VkInstance Instance;
	public static VkSurfaceKHR Surface;
	public static VkPhysicalDevice PhysicalDevice;
	public static VkDevice Device;
	public static VkQueue GraphicsQueue;
	public static VkQueue PresentQueue;

	public static VkPhysicalDeviceProperties Properties;
	public static VmaAllocator VmaAllocator;

	public static bool DebugUtilsExt;

	public static GpuBufferManager Buffers;
	public static BumpGpuBufferAllocator FrameAllocator;
	public static DescriptorSetLayoutManager DescriptorSetLayouts;
	public static DescriptorSetManager DescriptorSets;
	public static PipelineLayoutManager PipelineLayouts;
	public static PipelineManager Pipelines;
	public static ImageManager Images;
	public static SamplerManager Samplers;
	public static Swapchain Swapchain;
	public static CommandBufferManager CommandBuffers;

	private static Window Window;
	private static bool firstFrame = true;

	private static List<delegate void()> newFrameCallbacks = new .() ~ delete _;

	public static Result<void> Init(Window window) {
		VulkanNative.Initialize();
		VulkanNative.LoadPreInstanceFunctions();

		Window = window;

		CreateInstance().GetOrPropagate!();
		SetupDebugCallback().GetOrPropagate!();
		CreateSurface().GetOrPropagate!();
		FindPhysicalDevice().GetOrPropagate!();
		CreateDevice().GetOrPropagate!();

		vkGetPhysicalDeviceProperties(PhysicalDevice, &Properties);

		VmaAllocatorCreateInfo allocatorInfo = .() {
			physicalDevice = PhysicalDevice,
			device = Device,
			instance = Instance,
			vulkanApiVersion = Version(1, 3, 0)
		};
		vmaCreateAllocator(&allocatorInfo, &VmaAllocator);

		Buffers = new .();
		FrameAllocator = new .();
		DescriptorSetLayouts = new .();
		DescriptorSets = new .();
		PipelineLayouts = new .();
		Pipelines = new .();
		Images = new .();
		Samplers = new .();
		Swapchain = new .();
		CommandBuffers = new .();

		Swapchain.Recreate(window.size);

		Log.Info("Initialized Vulkan");
		return .Ok;
	}

	public static void Destroy() {
		vkDeviceWaitIdle(Device);

		DeleteAndNullify!(CommandBuffers);
		DeleteAndNullify!(Swapchain);
		DeleteAndNullify!(Samplers);
		DeleteAndNullify!(Images);
		DeleteAndNullify!(Pipelines);
		DeleteAndNullify!(PipelineLayouts);
		DeleteAndNullify!(DescriptorSets);
		DeleteAndNullify!(DescriptorSetLayouts);
		DeleteAndNullify!(FrameAllocator);
		DeleteAndNullify!(Buffers);

		vmaDestroyAllocator(VmaAllocator);
		VmaAllocator = 0;

		Device = .Null;
	}

	public static void NewFrame() {
		// Skip first frame
		if (firstFrame) {
			firstFrame = false;
			return;
		}

		// Call managers
		FrameAllocator.FreeAll();
		CommandBuffers.NewFrame();
		Pipelines.NewFrame();

		// Callbacks
		for (let callback in newFrameCallbacks) {
			callback();
		}

		newFrameCallbacks.ClearAndDeleteItems();
	}

	public static void RunOnNewFrame(delegate void() callback) {
		newFrameCallbacks.Add(callback);
	}

	// Initialization

	private static Result<void> CreateInstance() {
		VkApplicationInfo appInfo = .() {
			pApplicationName = Window.Title.ToScopeCStr!(),
			applicationVersion = Version(0, 1, 0),
			pEngineName = "Cacti",
			engineVersion = Version(0, 1, 0),
			apiVersion = Version(1, 3, 0)
		};

		List<StringView> extensions = Glfw.GetRequiredInstanceExtensions(.. scope .());
		List<char8*> extensionsRaw = scope .();
		for (let ext in extensions) extensionsRaw.Add(ext.ToScopeCStr!::());

		List<char8*> layers = scope .();

		uint32 count = 0;

#if DEBUG
		// Layers
		vkEnumerateInstanceLayerProperties(&count, null);

		VkLayerProperties[] availableLayers = scope .[count];
		vkEnumerateInstanceLayerProperties(&count, availableLayers.Ptr);

		for (var layer in availableLayers) {
			if (StringView(&layer.layerName) == "VK_LAYER_KHRONOS_validation") {
				layers.Add("VK_LAYER_KHRONOS_validation");
				break;
			}
		}

		if (layers.IsEmpty) Log.Warning("Vulkan validation layer is not supported, try installing the Vulkan SDK");
#endif

		// Extensions
		vkEnumerateInstanceExtensionProperties(null, &count, null);

		VkExtensionProperties[] avaiableExtensions = scope .[count];
		vkEnumerateInstanceExtensionProperties(null, &count, avaiableExtensions.Ptr);

		for (var ext in avaiableExtensions) {
			if (StringView(&ext.extensionName) == "VK_EXT_debug_utils") {
				extensionsRaw.Add("VK_EXT_debug_utils");
				DebugUtilsExt = true;

				break;
			}
		}

		if (!DebugUtilsExt) Log.Warning("Vulkan debug utils extension is not supported, try installing the Vulkan SDK");

		VkInstanceCreateInfo info = .() {
			pApplicationInfo = &appInfo,
			enabledLayerCount = (.) layers.Count,
			ppEnabledLayerNames = layers.Ptr,
			enabledExtensionCount = (.) extensionsRaw.Count,
			ppEnabledExtensionNames = extensionsRaw.Ptr
		};

		VkResult result = vkCreateInstance(&info, null, &Instance);
		if (result != .VK_SUCCESS) return Log.ErrorResult("Failed to create Vulkan instance: {}", result);

		if (VulkanNative.LoadPostInstanceFunctions(Instance) == .Err) return Log.ErrorResult("Failed to load Vulkan functions");
		return .Ok;
	}

	typealias DebugCallbackFunction = function VkBool32(VkDebugUtilsMessageSeverityFlagsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageType, VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, void* pUserData);

	private static Result<void> SetupDebugCallback() {
		if (!DebugUtilsExt) return .Ok;

		DebugCallbackFunction callback = => DebugCallback;

		VkDebugUtilsMessengerCreateInfoEXT info = .() {
			messageSeverity = .VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT | .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | .VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
			messageType = .VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | .VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT | .VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT,
			pfnUserCallback = callback
		};

		VkDebugUtilsMessengerEXT messenger;
		if (vkCreateDebugUtilsMessengerEXT(Instance, &info, null, &messenger) != .VK_SUCCESS) return Log.ErrorResult("Failed to setup debug callback");

		return .Ok;
	}

	private static VkBool32 DebugCallback(VkDebugUtilsMessageSeverityFlagsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageType, VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, void* pUserData) {
		LogLevel level;
		switch (messageSeverity) {
		case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT:	level = .Debug;
		//case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT:		level = .Info;
		case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT:	level = .Warning;
		case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT:	level = .Error;
		default:												return false;
		}

		Log.Log(level, .(pCallbackData.pMessage));
		return false;
	}

	private static Result<void> CreateSurface() {
		Glfw.CreateWindowSurface(.(Instance.Handle), Window.[Friend]handle, null, &Surface);
		if (Surface == .Null) return Log.ErrorResult("Failed to create Vulkan surface");

		return .Ok;
	}

	private static Result<void> FindPhysicalDevice() {
		uint32 count = 0;
		vkEnumeratePhysicalDevices(Instance, &count, null);
		if (count == 0) return Log.ErrorResult("Failed to find a suitable GPU");

		VkPhysicalDevice[] devices = scope .[count];
		vkEnumeratePhysicalDevices(Instance, &count, devices.Ptr);

		for (let device in devices) {
			VkPhysicalDeviceProperties properties = ?;
			vkGetPhysicalDeviceProperties(device, &properties);

			QueueFamilyIndices indices = FindQueueFamilies(device);

			if (properties.deviceType == .VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU && indices.Complete) {
				PhysicalDevice = device;

				Log.Info("GPU: {}", properties.deviceName);
				return .Ok;
			}
		}

		return Log.ErrorResult("Failed to find a suitable GPU");
	}

	private static Result<void> CreateDevice() {
		QueueFamilyIndices indices = FindQueueFamilies(PhysicalDevice);

		float priority = 1;

		HashSet<uint32> uniqueQueueFamilies = scope .();
		uniqueQueueFamilies.Add(indices.graphicsFamily.Value);
		uniqueQueueFamilies.Add(indices.presentFamily.Value);

		VkDeviceQueueCreateInfo[] queueInfos = scope .[uniqueQueueFamilies.Count];

		int i = 0;
		for (let queueFamily in uniqueQueueFamilies) {
			queueInfos[i] = .() {
				queueFamilyIndex = queueFamily,
				queueCount = 1,
				pQueuePriorities = &priority
			};

			i++;
		}

		VkPhysicalDeviceFeatures features = .() {
			independentBlend = true
		};

		VkPhysicalDeviceVulkan13Features features13 = .() {
			dynamicRendering = true
		};

		char8*[?] layers = .(
#if DEBUG
			"VK_LAYER_KHRONOS_validation"
#endif
		);

		char8*[?] extensions = .("VK_KHR_swapchain", "VK_KHR_dynamic_rendering");

		VkDeviceCreateInfo info = .() {
			pNext = &features13,
			queueCreateInfoCount = (.) queueInfos.Count,
			pQueueCreateInfos = queueInfos.Ptr,
			enabledLayerCount = layers.Count,
			ppEnabledLayerNames = &layers,
			enabledExtensionCount = extensions.Count,
			ppEnabledExtensionNames = &extensions,
			pEnabledFeatures = &features
		};

		vkCreateDevice(PhysicalDevice, &info, null, &Device);
		if (Device == .Null) return Log.ErrorResult("Failed to create Vulkan device");

		vkGetDeviceQueue(Device, indices.graphicsFamily.Value, 0, &GraphicsQueue);
		if (GraphicsQueue == .Null) return Log.ErrorResult("Failed to create Vulkan graphics queue");

		vkGetDeviceQueue(Device, indices.presentFamily.Value, 0, &PresentQueue);
		if (PresentQueue == .Null) return Log.ErrorResult("Failed to create Vulkan present queue");

		return .Ok;
	}

	// Other

	public static uint32 Version(uint32 major, uint32 minor, uint32 patch) {
		return (major << 22) | (minor << 12) | patch;
	}

	public struct QueueFamilyIndices {
		public uint32? graphicsFamily;
		public uint32? presentFamily;

		public bool Complete { get {
			return graphicsFamily.HasValue && presentFamily.HasValue;
		} }
	}

	public static QueueFamilyIndices FindQueueFamilies(VkPhysicalDevice device) {
		QueueFamilyIndices indices = .();

		uint32 count = 0;
		vkGetPhysicalDeviceQueueFamilyProperties(device, &count, null);

		VkQueueFamilyProperties[] families = scope .[count];
		vkGetPhysicalDeviceQueueFamilyProperties(device, &count, families.Ptr);

		uint32 i = 0;
		for (let family in families) {
			if (family.queueFlags & .VK_QUEUE_GRAPHICS_BIT != 0) indices.graphicsFamily = i;

			VkBool32 supported = false;
			vkGetPhysicalDeviceSurfaceSupportKHR(device, i, Surface, &supported);
			if (supported) indices.presentFamily = i;

			i++;
		}

		return indices;
	}
}