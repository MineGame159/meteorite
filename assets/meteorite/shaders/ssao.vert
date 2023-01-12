#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texCoord;

layout(location = 0) out vec3 v_Position;
layout(location = 1) out vec2 v_TexCoord;

#include <lib/api.glsl>

void main() {
    gl_Position = vec4(position, 1.0);
    v_Position = (api_InverseProjection * vec4(position, 1.0)).xyz;;
    v_TexCoord = texCoord;
}