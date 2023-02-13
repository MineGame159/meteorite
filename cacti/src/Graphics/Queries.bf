using System;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class Queries {
	public const int MAX_QUERIES = 16 * 2;

	public VkQueryPool pool ~ vkDestroyQueryPool(Gfx.Device, _, null);
	public TimeSpan total;

	private uint32 i;

	public this() {
		VkQueryPoolCreateInfo info = .() {
			queryType = .VK_QUERY_TYPE_TIMESTAMP,
			queryCount = MAX_QUERIES
		};

		vkCreateQueryPool(Gfx.Device, &info, null, &pool);
		vkResetQueryPool(Gfx.Device, pool, 0, MAX_QUERIES);
	}

	[Tracy.Profile]
	public void NewFrame() {
		// Query results
		Runtime.Assert(i % 2 == 0);
		uint64[] queries = scope .[i];

		VkResult result = vkGetQueryPoolResults(Gfx.Device, pool, 0, i, sizeof(uint64) * i, queries.Ptr, sizeof(uint64), .VK_QUERY_RESULT_64_BIT);
		if (result == .VK_SUCCESS) {
			double milliseconds = 0;

			for (int j = 0; j < i; j += 2) {
				milliseconds += (queries[j + 1] - queries[j]) * Gfx.Properties.limits.timestampPeriod / 1000000.0;
			}

			total = .((.) (milliseconds * TimeSpan.TicksPerMillisecond));
		}
		else {
			Log.Warning("Failed to get GPU query results: {}", result);
		}

		// Reset pool
		vkResetQueryPool(Gfx.Device, pool, 0, i);
		i = 0;
	}

	public uint32 Get() {
		Runtime.Assert(i < MAX_QUERIES);
		return i++;
	}
}