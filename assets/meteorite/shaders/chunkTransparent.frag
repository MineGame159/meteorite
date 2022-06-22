layout(location = 0) in vec2 v_Uv1;
layout(location = 1) in vec2 v_Uv2;
layout(location = 2) in float v_Blend;
layout(location = 3) in vec4 v_Color;
layout(location = 4) in vec3 v_Normal;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 normal;

layout(set = 0, binding = 0) uniform texture2D u_Texture;
layout(set = 0, binding = 1) uniform sampler u_Sampler;

#ifdef TONEMAP
    #include lib/tonemap
#endif

void main() {
    vec4 color1 = texture(sampler2D(u_Texture, u_Sampler), v_Uv1);
    vec4 color2 = texture(sampler2D(u_Texture, u_Sampler), v_Uv2);

    vec4 c = mix(color1, color2, v_Blend) * v_Color;

    color = c;
    
    normal.xyz = v_Normal;
}