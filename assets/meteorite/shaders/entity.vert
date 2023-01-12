#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec4 normal;
layout(location = 2) in vec2 texCoord;
layout(location = 3) in vec4 color;

layout(location = 0) out vec2 v_TexCoord;
layout(location = 1) out float v_Diffuse;
layout(location = 2) out vec4 v_Normal;
layout(location = 3) out vec4 v_Color;

#include <lib/api.glsl>

const vec3 LIGHT1      = vec3( 0.104196384,  0.947239857, -0.303116754);
const vec3 LIGHT2      = vec3(-0.104196384,  0.947239857,  0.303116754);
const vec3 LIGHT2_DARK = vec3(-0.104196384, -0.947239857,  0.303116754);

float diffuse(vec3 normal) {
    float l1 = max(0.0, dot(LIGHT1, normal));
    float l2 = max(0.0, dot(LIGHT2, normal));

    return 0.5 + min(0.5, l1 + l2);
}

void main() {
    gl_Position = api_ProjectionView * vec4(position, 1.0);
    v_TexCoord = texCoord;
    v_Diffuse = diffuse(normal.xyz);
    v_Normal = api_InverseView * normal;
    v_Color = color;
}