using System;

using Cacti;

namespace Meteorite;

class LightmapManager {
	private GpuImage image ~ delete _;
	private DescriptorSet set ~ delete _;
	private bool uploaded = true;

	private float flickerIntensity;
	private bool dirty;

	public this() {
		image = Gfx.Images.Create(.RGBA, .Normal, .(16, 16), "Lightmap");
		set = Gfx.DescriptorSets.Create(Gfxa.IMAGE_SET_LAYOUT, .SampledImage(image, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, Gfxa.LINEAR_SAMPLER));
	}

	public void Bind(CommandBuffer cmds, uint32 index) {
		cmds.Bind(set, index);
	}

	public void Tick() {
	    flickerIntensity += (float) ((Utils.RANDOM.NextDouble() - Utils.RANDOM.NextDouble()) * Utils.RANDOM.NextDouble() * Utils.RANDOM.NextDouble() * 0.1);
	    flickerIntensity *= 0.9f;
		dirty = true;
	}

	public void Update(float delta) {
	    if (!dirty) return;
	    dirty = false;

		Meteorite me = Meteorite.INSTANCE;

	    World clientWorld = me.world;
	    if (clientWorld == null || me.player == null) return;

		Color* pixels = scope .[16 * 16]*;

	    float starBrightness = clientWorld.GetSkyDarken();
	    //float g = clientWorld.GetLightningTicksLeft() > 0 ? 1.0f : f * 0.95f + 0.05f;
		float starBrightness2 = starBrightness * 0.95f + 0.05f;
		//float h = this.client.options.getDarknessEffectScale().getValue().floatValue();
	    float darknessScale = 1f;
	    float darknessFactor = GetDarknessFactor(delta) * darknessScale;
	    float darkness = GetDarkness(me.player, darknessFactor, delta) * darknessScale;
		//float k = me.player.getUnderwaterVisibility();
	    float underwaterVisibility = 0f;
		//float l = me.player.hasStatusEffect(StatusEffects.NIGHT_VISION) ? GameRenderer.getNightVisionStrength(this.client.player, delta) : (k > 0.0f && this.client.player.hasStatusEffect(StatusEffects.CONDUIT_POWER) ? k : 0.0f);
		float l = ((underwaterVisibility > 0f && false) ? underwaterVisibility : 0f);
		Vec3f vector3f = Vec3f(starBrightness, starBrightness, 1).Lerp(0.35f, .(1, 1, 1));
	    float flicker = this.flickerIntensity + 1.5f;
	    Vec3f vector3f2 = .();

	    for (int y < 16) {
	        for (int x < 16) {
	            float v;
	            Vec3f vector3f4;
	            float u;
	            float q;
	            float p = GetBrightness(clientWorld.dimension, y) * starBrightness2;
	            float r_ = q = GetBrightness(clientWorld.dimension, x) * flicker;
	            float s = q * ((q * 0.6f + 0.4f) * 0.6f + 0.4f);
	            float t = q * (q * q * 0.6f + 0.4f);
	            vector3f2 = .(r_, s, t);

				//bool bl = clientWorld.getDimensionEffects().shouldBrightenLighting();
	            bool shouldBrightenLighting = false;
	            if (shouldBrightenLighting) {
	                vector3f2 = vector3f2.Lerp(0.25f, .(0.99f, 1.12f, 1.0f)).Clamp(0, 1);
	            } else {
	                Vec3f vector3f3 = vector3f * p;
	                vector3f2 += vector3f3;
	                vector3f2 = vector3f2.Lerp(0.04f, .(0.75f, 0.75f, 0.75f));
	                /*if (this.renderer.getSkyDarkness(delta) > 0.0f) {
	                    u = this.renderer.getSkyDarkness(delta);
	                    vector3f4 = vector3f2 * Vec3f(0.7f, 0.6f, 0.6f);
	                    vector3f2 = vector3f2.Lerp(u, vector3f4);
	                }*/
	            }

	            if (l > 0f && (v = Math.Max(vector3f2.x, Math.Max(vector3f2.y, vector3f2.z))) < 1f) {
	                u = 1f / v;
	                vector3f4 = vector3f2 * u;
	                vector3f2 = vector3f2.Lerp(l, vector3f4);
	            }
	            if (!shouldBrightenLighting) {
	                if (darkness > 0f) {
	                    vector3f2 += .(-darkness, -darkness, -darkness);
	                }
					vector3f2 = vector3f2.Clamp(0, 1);
	            }

	            //float v2 = this.client.options.getGamma().getValue().floatValue();
				float v2 = 0.5f;
	            Vec3f vector3f5 = .(EaseOutQuart(vector3f2.x), EaseOutQuart(vector3f2.y), EaseOutQuart(vector3f2.z));
	            vector3f2 = vector3f2.Lerp(Math.Max(0f, v2 - darknessFactor), vector3f5);
	            vector3f2 = vector3f2.Lerp(0.04f, .(0.75f, 0.75f, 0.75f));
	            vector3f2 = vector3f2.Clamp(0, 1) * 255;

	            uint8 r = (.) vector3f2.x;
	            uint8 g = (.) vector3f2.y;
	            uint8 b = (.) vector3f2.z;

				pixels[y * 16 + x] = .(r, g, b);
	        }
	    }

		if (!uploaded) Log.Warning("LightmapManager tried to upload new lightmap image before the previous one finished uploading");
		
		uploaded = false;
	    Gfx.Uploads.UploadImage(image, pixels, 0, new () => uploaded = true);
	}

	private float GetDarknessFactor(float delta) {
	    /*StatusEffectInstance statusEffectInstance;
	    if (this.client.player.hasStatusEffect(StatusEffects.DARKNESS) && (statusEffectInstance = this.client.player.getStatusEffect(StatusEffects.DARKNESS)) != null && statusEffectInstance.getFactorCalculationData().isPresent()) {
	        return statusEffectInstance.getFactorCalculationData().get().lerp(this.client.player, delta);
	    }*/
	    return 0.0f;
	}

	private float GetDarkness(LivingEntity entity, float factor, float delta) {
	    float f = 0.45f * factor;
		return Math.Max(0f, Math.Cos(((float) entity.tickCount - delta) * (float) Math.PI_f * 0.025f) * f);
	}

	private float EaseOutQuart(float x) {
	    float f = 1f - x;
	    return 1f - f * f * f * f;
	}

	public static float GetBrightness(DimensionType dimension, int lightLevel) {
	    float f = (float) lightLevel / 15f;
	    float g = f / (4f - 3f * f);
	    return Utils.Lerp(dimension.ambientLight, g, 1f);
	}
}