#version 460

layout(location = 0) in vec2 v_TexCoord;
layout(location = 1) in float v_Diffuse;
layout(location = 2) in vec4 v_Normal;
layout(location = 3) in vec4 v_Color;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 normal;

layout(set = 1, binding = 0) uniform sampler2D u_Texture;

void main() {
    vec4 c = texture(u_Texture, v_TexCoord);
    if (c.a <= 0.75) discard;

    c *= vec4(v_Diffuse, v_Diffuse, v_Diffuse, 1.0);

    color = c * v_Color;
    normal = v_Normal;
}