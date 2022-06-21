// https://catlikecoding.com/unity/tutorials/custom-srp/fxaa/

// Trims the algorithm from processing darks.
//   0.0833 - upper limit (default, the start of visible unfiltered edges)
//   0.0625 - high quality (faster)
//   0.0312 - visible limit (slower)
#define FIXED_THRESHOLD 0.0625

// The minimum amount of local contrast required to apply algorithm.
//   0.333 - too little (faster)
//   0.250 - low quality
//   0.166 - default
//   0.125 - high quality 
//   0.063 - overkill (slower)
#define RELATIVE_THRESHOLD 0.125

// Choose the amount of sub-pixel aliasing removal.
// This can effect sharpness.
//   1.00 - upper limit (softer)
//   0.75 - default amount of filtering
//   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
//   0.25 - almost off
//   0.00 - completely off
#define SUBPIXEL_BLENDING 0.75

#ifdef FXAA_QUALITY_LOW
	#define EXTRA_EDGE_STEPS 3
	#define EDGE_STEP_SIZES 1.5, 2.0, 2.0
	#define LAST_EDGE_STEP_GUESS 8.0
#elif FXAA_QUALITY_MEDIUM
	#define EXTRA_EDGE_STEPS 8
	#define EDGE_STEP_SIZES 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0
	#define LAST_EDGE_STEP_GUESS 8.0
#else
	#define EXTRA_EDGE_STEPS 10
	#define EDGE_STEP_SIZES 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0
	#define LAST_EDGE_STEP_GUESS 8.0
#endif

float edgeStepSizes[EXTRA_EDGE_STEPS] = { EDGE_STEP_SIZES };

#define RESOLUTION_TEXEL (1.0 / RESOLUTION)

vec4 GetSource(vec2 uv) {
    return texture(SAMPLER, uv);
}

float Luminance(vec4 color) {
    return dot(color, vec4(0.2126, 0.7152, 0.0722, 0.0));
}

float GetLuma(vec2 uv) {
	return sqrt(Luminance(GetSource(uv)));
}

float GetLuma(vec2 uv, float uOffset, float vOffset) {
	uv += vec2(uOffset, vOffset) * RESOLUTION_TEXEL;
    return GetLuma(uv);
}

struct LumaNeighborhood {
	float m;
    float n;
    float e;
    float s;
    float w;
    float ne;
    float se;
    float sw;
    float nw;

    float highest;
    float lowest;
    float range;
};

LumaNeighborhood GetLumaNeighborhood(vec2 uv) {
    float m = GetLuma(uv);
    float n = GetLuma(uv, 0.0, 1.0);
    float e = GetLuma(uv, 1.0, 0.0);
    float s = GetLuma(uv, 0.0, -1.0);
    float w = GetLuma(uv, -1.0, 0.0);
    float ne = GetLuma(uv, 1.0, 1.0);
    float se = GetLuma(uv, 1.0, -1.0);
    float sw = GetLuma(uv, -1.0, -1.0);
    float nw = GetLuma(uv, -1.0, 1.0);

    float highest = max(max(max(max(m, n), e), s), w);
    float lowest = min(min(min(min(m, n), e), s), w);

    return LumaNeighborhood(
        m, n, e, s, w, ne, se, sw, nw,
        highest, lowest, highest - lowest
    );
}

bool CanSkipFXAA(LumaNeighborhood luma) {
	return luma.range < max(FIXED_THRESHOLD, RELATIVE_THRESHOLD * luma.highest);
}

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

float GetSubpixelBlendFactor(LumaNeighborhood luma) {
	float filter = 2.0 * (luma.n + luma.e + luma.s + luma.w);
	filter += luma.ne + luma.nw + luma.se + luma.sw;
	filter *= 1.0 / 12.0;
	filter = abs(filter - luma.m);
	filter = saturate(filter / luma.range);
	filter = smoothstep(0, 1, filter);
	return filter * filter * SUBPIXEL_BLENDING;
}

bool IsHorizontalEdge(LumaNeighborhood luma) {
	float horizontal = 2.0 * abs(luma.n + luma.s - 2.0 * luma.m) + abs(luma.ne + luma.se - 2.0 * luma.e) + abs(luma.nw + luma.sw - 2.0 * luma.w);
	float vertical = 2.0 * abs(luma.e + luma.w - 2.0 * luma.m) + abs(luma.ne + luma.nw - 2.0 * luma.n) + abs(luma.se + luma.sw - 2.0 * luma.s);
	return horizontal >= vertical;
}

struct FXAAEdge {
	bool isHorizontal;
    float pixelStep;
    float lumaGradient;
    float otherLuma;
};

FXAAEdge GetFXAAEdge(LumaNeighborhood luma) {
    bool isHorizontal = IsHorizontalEdge(luma);
    float pixelStep;
    float lumaGradient, otherLuma;

    float lumaP, lumaN;
	if (isHorizontal) {
		pixelStep = RESOLUTION_TEXEL.y;
		lumaP = luma.n;
		lumaN = luma.s;
	}
	else {
		pixelStep = RESOLUTION_TEXEL.x;
		lumaP = luma.e;
		lumaN = luma.w;
	}
	float gradientP = abs(lumaP - luma.m);
	float gradientN = abs(lumaN - luma.m);

	if (gradientP < gradientN) {
		pixelStep = -pixelStep;
		lumaGradient = gradientN;
		otherLuma = lumaN;
	}
	else {
		lumaGradient = gradientP;
		otherLuma = lumaP;
	}

    return FXAAEdge(isHorizontal, pixelStep, lumaGradient, otherLuma);
}

float GetEdgeBlendFactor(LumaNeighborhood luma, FXAAEdge edge, vec2 uv) {
    vec2 edgeUV = uv;
	vec2 uvStep = vec2(0.0);
	if (edge.isHorizontal) {
		edgeUV.y += 0.5 * edge.pixelStep;
		uvStep.x = RESOLUTION_TEXEL.x;
	}
	else {
		edgeUV.x += 0.5 * edge.pixelStep;
		uvStep.y = RESOLUTION_TEXEL.y;
	}

	float edgeLuma = 0.5 * (luma.m + edge.otherLuma);
	float gradientThreshold = 0.25 * edge.lumaGradient;
			
	vec2 uvP = edgeUV + uvStep;
	float lumaDeltaP = GetLuma(uvP) - edgeLuma;
	bool atEndP = abs(lumaDeltaP) >= gradientThreshold;

	for (int i = 0; i < EXTRA_EDGE_STEPS && !atEndP; i++) {
		uvP += uvStep * edgeStepSizes[i];
		lumaDeltaP = GetLuma(uvP) - edgeLuma;
		atEndP = abs(lumaDeltaP) >= gradientThreshold;
	}
	if (!atEndP) {
		uvP += uvStep * LAST_EDGE_STEP_GUESS;
	}

	vec2 uvN = edgeUV - uvStep;
	float lumaDeltaN = GetLuma(uvN) - edgeLuma;
	bool atEndN = abs(lumaDeltaN) >= gradientThreshold;

	for (int i = 0; i < EXTRA_EDGE_STEPS && !atEndN; i++) {
		uvN -= uvStep * edgeStepSizes[i];
		lumaDeltaN = GetLuma(uvN) - edgeLuma;
		atEndN = abs(lumaDeltaN) >= gradientThreshold;
	}
	if (!atEndN) {
		uvN -= uvStep * LAST_EDGE_STEP_GUESS;
	}

	float distanceToEndP, distanceToEndN;
	if (edge.isHorizontal) {
		distanceToEndP = uvP.x - uv.x;
		distanceToEndN = uv.x - uvN.x;
	}
	else {
		distanceToEndP = uvP.y - uv.y;
		distanceToEndN = uv.y - uvN.y;
	}

	float distanceToNearestEnd;
	bool deltaSign;
	if (distanceToEndP <= distanceToEndN) {
		distanceToNearestEnd = distanceToEndP;
		deltaSign = lumaDeltaP >= 0;
	}
	else {
		distanceToNearestEnd = distanceToEndN;
		deltaSign = lumaDeltaN >= 0;
	}

	if (deltaSign == (luma.m - edgeLuma >= 0)) {
		return 0.0;
	}
	else {
		return 0.5 - distanceToNearestEnd / (distanceToEndP + distanceToEndN);
	}
}

vec4 fxaa(vec2 uv) {
    LumaNeighborhood luma = GetLumaNeighborhood(uv);

    if (CanSkipFXAA(luma)) return GetSource(uv);

    FXAAEdge edge = GetFXAAEdge(luma);

    float blendFactor = max(GetSubpixelBlendFactor(luma), GetEdgeBlendFactor(luma, edge, uv));
	vec2 blendUV = uv;
    
	if (edge.isHorizontal) blendUV.y += blendFactor * edge.pixelStep;
	else blendUV.x += blendFactor * edge.pixelStep;

	return GetSource(blendUV);
}