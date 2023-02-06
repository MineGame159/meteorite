#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texcoord;

layout(location = 0) out vec2 v_Texcoord;
layout(location = 1) out vec2 v_Pixcoord;
layout(location = 2) out vec4[3] v_Offset;

#include <lib/smaa.glsl>

void main() {
    gl_Position = vec4(position, 1.0);
    v_Texcoord = texcoord;

    SMAABlendingWeightCalculationVS(texcoord, v_Pixcoord, v_Offset);
}