layout(location = 0) in vec2 v_TexCoord;

layout(location = 0) out vec4 color;

#include lib/api

layout(set = 1, binding = 0) uniform texture2D u_Texture;
layout(set = 1, binding = 1) uniform sampler u_Sampler;
#define SAMPLER sampler2D(u_Texture, u_Sampler)

layout(set = 2, binding = 0) uniform texture2D u_SsaoTexture;
layout(set = 2, binding = 1) uniform sampler u_SsaoSampler;
#define SSAO_SAMPLER sampler2D(u_SsaoTexture, u_SsaoSampler)

#ifdef FXAA
    #include lib/fxaa
#endif

#ifdef SSAO
    #include lib/ssao
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