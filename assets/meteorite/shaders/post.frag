#version 460
#extension GL_EXT_samplerless_texture_functions : enable

layout(location = 0) in vec2 v_Texcoord;

layout(location = 0) out vec4 color;

#include <lib/api.glsl>

layout(set = 1, binding = 0) uniform sampler2D u_ColorTexture;
#define SAMPLER u_ColorTexture

layout(set = 2, binding = 0) uniform sampler2D u_SsaoTexture;
#define SSAO_SAMPLER u_SsaoTexture

layout(set = 3, binding = 0) uniform sampler2D u_SmaaBlendTexture;

#ifdef SMAA_ENABLED
    layout(location = 1) in vec4 v_Offset;

    #include <lib/smaa.glsl>
#endif

#ifdef SSAO_ENABLED
    #include <lib/ssao.glsl>
#endif

void main() {
    #ifdef SMAA_ENABLED
        color = SMAANeighborhoodBlendingPS(v_Texcoord, v_Offset, u_ColorTexture, u_SmaaBlendTexture);
    #else
        color = texelFetch(u_ColorTexture, ivec2(gl_FragCoord.xy), 0);
    #endif

    #ifdef SSAO_ENABLED
        color.rgb *= ssao(v_Texcoord);
    #endif
}