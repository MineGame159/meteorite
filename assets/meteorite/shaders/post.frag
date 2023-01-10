#version 460
#extension GL_EXT_samplerless_texture_functions : enable

layout(location = 0) in vec2 v_TexCoord;

layout(location = 0) out vec4 color;

#include <lib/api.glsl>

layout(set = 1, binding = 0) uniform sampler2D u_Texture;
#define SAMPLER u_Texture

layout(set = 2, binding = 0) uniform sampler2D u_SsaoTexture;
#define SSAO_SAMPLER u_SsaoTexture

#ifdef FXAA
    #include <lib/fxaa.glsl>
#endif

#ifdef SSAO
    #include <lib/ssao.glsl>
#endif

void main() {
    #ifdef FXAA
        color = fxaa(v_TexCoord);
    #else
        color = texelFetch(u_Texture, ivec2(gl_FragCoord.xy), 0);
    #endif

    #ifdef SSAO
        color.rgb *= ssao(v_TexCoord);
    #endif
}