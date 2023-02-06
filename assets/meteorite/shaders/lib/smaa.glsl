#define SMAA_RT_METRICS vec4(1.0 / api_Resolution, api_Resolution)
#define SMAA_GLSL_4

#if !defined(SMAA_PRESET_MEDIUM) && !defined(SMAA_PRESET_HIGH) && !defined(SMAA_PRESET_ULTRA)
    #error You must set either SMAA_PRESET_MEDIUM, SMAA_PRESET_HIGH or SMAA_PRESET_ULTRA
#endif

#ifdef VERTEX
    #define SMAA_INCLUDE_VS 1
    #define SMAA_INCLUDE_PS 0
#else
    #define SMAA_INCLUDE_VS 0
    #define SMAA_INCLUDE_PS 1
#endif

#include <lib/api.glsl>
#include <lib/SMAA.hlsl>