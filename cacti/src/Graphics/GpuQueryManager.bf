using System;
using System.Collections;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

namespace Cacti.Graphics;

class GpuQuery {
	private uint32 startId = GpuQueryManager.MAX_QUERIES;
	private uint32 endId = GpuQueryManager.MAX_QUERIES;

	private uint64 start;
	private uint64 end;

	public TimeSpan Duration => .((.) ((end - start) * (double) Gfx.Properties.limits.timestampPeriod / 100.0));
}

class GpuQueryManager {
	public const int MAX_QUERIES = 32;
	
	public VkQueryPool pool ~ vkDestroyQueryPool(Gfx.Device, _, null);
	private List<GpuQuery> queries = new .() ~ delete _;

	public this() {
		VkQueryPoolCreateInfo info = .() {
			queryType = .VK_QUERY_TYPE_TIMESTAMP,
			queryCount = MAX_QUERIES * 2
		};

		vkCreateQueryPool(Gfx.Device, &info, null, &pool);
		vkResetQueryPool(Gfx.Device, pool, 0, MAX_QUERIES * 2);
	}

	[Tracy.Profile]
	public void NewFrame() {
		// Query results
		uint64[] timestamps = scope .[queries.Count * 2];

		VkResult result = vkGetQueryPoolResults(Gfx.Device, pool, 0, (.) timestamps.Count, (.) (sizeof(uint64) * timestamps.Count), timestamps.Ptr, sizeof(uint64), .VK_QUERY_RESULT_64_BIT);

		if (result != .VK_SUCCESS) {
			Internal.MemSet(timestamps.Ptr, 0, sizeof(uint64) * timestamps.Count);
			Log.Warning("Failed to get GPU query results: {}", result);
		}

		for (let query in queries) {
			query.[Friend]start = timestamps[query.[Friend]startId];
			query.[Friend]end = timestamps[query.[Friend]endId];
			
			query.[Friend]startId = 0;
			query.[Friend]endId = 0;
		}

		// Reset pool
		vkResetQueryPool(Gfx.Device, pool, 0, (.) timestamps.Count);
		queries.Clear();
	}

	private void Prepare(GpuQuery query) {
		Debug.Assert(queries.Count < MAX_QUERIES);

		query.[Friend]startId = (.) queries.Count * 2;
		query.[Friend]endId = (.) queries.Count * 2 + 1;
		
		queries.Add(query);
	}
}