layout(location = 0) in vec2 v_TexCoord;

layout(location = 0) out vec4 color;

layout(push_constant, std430) uniform pushConstants {
    vec2 size;
} pc;

layout(set = 0, binding = 0) uniform texture2D u_Texture;
layout(set = 0, binding = 1) uniform sampler u_Sampler;

#define SAMPLER sampler2D(u_Texture, u_Sampler)
#define RESOLUTION pc.size

#ifdef FXAA
    #include lib/fxaa
#endif

void main() {
    #ifdef FXAA
        color = fxaa(v_TexCoord);
    #else
        color = texelFetch(u_Texture, ivec2(gl_FragCoord.xy), 0);
    #endif
}