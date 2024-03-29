#version 460

layout(location = 0) in vec2 v_Uv1;
layout(location = 1) in vec2 v_Uv2;
layout(location = 2) in float v_Blend;
layout(location = 3) in vec4 v_Color;
layout(location = 4) in vec4 v_Normal;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 normal;

layout(set = 1, binding = 0) uniform sampler2D u_Texture;

void main() {
    vec4 color1 = texture(u_Texture, v_Uv1);
    vec4 color2 = texture(u_Texture, v_Uv2);

    vec4 c = mix(color1, color2, v_Blend);

    #ifdef SOLID
        if (c.a <= 0.75) discard;
    #endif

    color = c * v_Color;
    normal = v_Normal;
}