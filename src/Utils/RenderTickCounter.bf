using System;
using System.Diagnostics;

namespace Meteorite;

class RenderTickCounter {
	private Stopwatch sw ~ delete _;

	public float tickDelta;
	public float lastFrameDuration;
	private int64 prevTimeMillis;
	private float tickTime;

	public this(float tps, int64 timeMillis) {
		this.sw = new .(true);
	    this.tickTime = 1000.0f / tps;
	    this.prevTimeMillis = timeMillis;
	}

	public int BeginRenderTick() {
		int64 timeMillis = sw.ElapsedMilliseconds;

		this.lastFrameDuration = (float)(timeMillis - this.prevTimeMillis) / this.tickTime;
		this.prevTimeMillis = timeMillis;
		this.tickDelta += this.lastFrameDuration;
		int i = (int)this.tickDelta;
		this.tickDelta -= (float)i;
		return i;
	}
}