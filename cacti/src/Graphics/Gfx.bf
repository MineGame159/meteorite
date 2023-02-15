using System;
using System.Collections;

using GLFW;

using Bulkan;
using Bulkan.Utilities;
using static Bulkan.VulkanNative;
using static Bulkan.Utilities.VulkanMemoryAllocator;

namespace Cacti.Graphics;

static class Gfx {
	// Vulkan objects
	public static VkInstance Instance;
	public static VkSurfaceKHR Surface;
	public static VkPhysicalDevice PhysicalDevice;
	public static VkDevice Device;
	public static VkQueue GraphicsQueue;
	public static VkQueue PresentQueue;

	public static VkPhysicalDeviceProperties Properties;
	public static VmaAllocator VmaAllocator;

	// Helper objects
	public static GpuBufferManager Buffers;
	public static BumpGpuBufferAllocator FrameAllocator;

	public static GpuImageManager Images;
	public static SamplerManager Samplers;

	public static ShaderManager Shaders;
	public static PipelineLayoutManager PipelineLayouts;
	public static PipelineManager Pipelines;

	public static CommandBufferManager CommandBuffers;
	public static DescriptorSetLayoutManager DescriptorSetLayouts;
	public static DescriptorSetManager DescriptorSets;
	public static RenderPassManager RenderPasses;

	public static UploadManager Uploads;
	public static GpuQueryManager Queries;

	public static Swapchain Swapchain;

	// Other
	public static bool DebugUtilsExt;

	private static Window Window;
	private static bool firstFrame = true;

	private static List<DoubleRefCounted> toRelease = new .() ~ delete _;

	public static Result<void> Init(Window window) {
		// Initialize Vulkan library
		VulkanNative.Initialize();
		VulkanNative.LoadPreInstanceFunctions();

		Window = window;

		// Create Vulkan objects
		CreateInstance().GetOrPropagate!();
		SetupDebugCallback().GetOrPropagate!();
		CreateSurface().GetOrPropagate!();
		FindPhysicalDevice().GetOrPropagate!();
		CreateDevice().GetOrPropagate!();

		// Query GPU properties
		vkGetPhysicalDeviceProperties(PhysicalDevice, &Properties);

		// Create VMA allocator
		VmaAllocatorCreateInfo allocatorInfo = .() {
			physicalDevice = PhysicalDevice,
			device = Device,
			instance = Instance,
			vulkanApiVersion = Version(1, 3, 0)
		};
		vmaCreateAllocator(&allocatorInfo, &VmaAllocator);

		// Create helper objects
		Buffers = new .();
		FrameAllocator = new .();

		Images = new .();
		Samplers = new .();

		Shaders = new .();
		PipelineLayouts = new .();
		Pipelines = new .();

		CommandBuffers = new .();
		DescriptorSetLayouts = new .();
		DescriptorSets = new .();
		RenderPasses = new .();

		Uploads = new .();
		Queries = new .();

		Swapchain = new .();
		Swapchain.Recreate(window.size).GetOrPropagate!();
		
		// Return
		Log.Info("Initialized Vulkan");
		return .Ok;
	}

	public static void Destroy() {
		// Wait for the GPU to finish executing commands
		vkDeviceWaitIdle(Device);

		// Destroy helper objects
		DescriptorSets.Destroy();
		RenderPasses.Destroy();

		// Delete helper objects 1
		DeleteAndNullify!(Swapchain);
		DeleteAndNullify!(Queries);
		DeleteAndNullify!(Uploads);
		DeleteAndNullify!(FrameAllocator);

		// Release reference counted items
		ReleaseItems();

		// Delete helper objects 2
		DeleteAndNullify!(RenderPasses);
		DeleteAndNullify!(DescriptorSets);
		DeleteAndNullify!(DescriptorSetLayouts);
		DeleteAndNullify!(CommandBuffers);

		DeleteAndNullify!(Pipelines);
		DeleteAndNullify!(PipelineLayouts);
		DeleteAndNullify!(Shaders);

		DeleteAndNullify!(Samplers);
		DeleteAndNullify!(Images);

		DeleteAndNullify!(Buffers);

		// Release reference counted items
		ReleaseItems();

		// Delete VMA allocator
		vmaDestroyAllocator(VmaAllocator);
		VmaAllocator = 0;

		// Destroy Vulkan objects
		Device = .Null;
	}

	public static void ReleaseNextFrame(DoubleRefCounted item) {
		toRelease.Add(item);
	}

	[Tracy.Profile]
	public static void NewFrame() {
		// Skip first frame
		if (firstFrame) {
			firstFrame = false;
			return;
		}

		// Call managers
		FrameAllocator.FreeAll();
		DescriptorSets.NewFrame();
		CommandBuffers.NewFrame();
		RenderPasses.NewFrame();
		Uploads.NewFrame();
		Queries.NewFrame();

		// Release reference counted items
		ReleaseItems();
	}

	public static uint64 UsedMemory { get {
		VmaBudget[VK_MAX_MEMORY_HEAPS] budgets = .();
		vmaGetHeapBudgets(VmaAllocator, &budgets);

		uint64 usage = 0;

		for (let budget in budgets) {
			usage += budget.usage;
		}

		return usage;
	} }

	private static void ReleaseItems() {
		for (DoubleRefCounted item in toRelease) {
			item.ReleaseWeak();
		}

		toRelease.Clear();
	}

	// Initialization

	private static Result<void> CreateInstance() {
		VkApplicationInfo appInfo = .() {
			pApplicationName = Window.Title.ToScopeCStr!(),
			applicationVersion = Version(0, 1, 0),
			pEngineName = "Cacti",
			engineVersion = Version(0, 1, 0),
			apiVersion = Version(1, 2, 0)
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

		VkPhysicalDevice lastValidDevice = .Null;
		VkPhysicalDeviceProperties lastValidDeviceProperties = ?;

		for (let device in devices) {
			VkPhysicalDeviceProperties properties = ?;
			vkGetPhysicalDeviceProperties(device, &properties);

			QueueFamilyIndices indices = FindQueueFamilies(device);

			if (indices.Complete) {
				lastValidDevice = device;
				lastValidDeviceProperties = properties;

				if (properties.deviceType == .VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
					break;
				}
			}
		}

		if (lastValidDevice == .Null) {
			return Log.ErrorResult("Failed to find a suitable GPU");
		}

		Log.Info("GPU: {}", lastValidDeviceProperties.deviceName);
		PhysicalDevice = lastValidDevice;

		return .Ok;
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
			independentBlend = true,
		};

		VkPhysicalDeviceVulkan12Features features12 = .() {
			separateDepthStencilLayouts = true,
			hostQueryReset = true
		};

		char8*[?] layers = .(
#if DEBUG
			"VK_LAYER_KHRONOS_validation"
#endif
		);

		char8*[?] extensions = .("VK_KHR_swapchain");

		VkDeviceCreateInfo info = .() {
			pNext = &features12,
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