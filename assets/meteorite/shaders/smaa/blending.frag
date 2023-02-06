#version 460

layout(location = 0) out vec4 blend;

layout(location = 0) in vec2 v_Texcoord;
layout(location = 1) in vec2 v_Pixcoord;
layout(location = 2) in vec4[3] v_Offset;

layout(set = 1, binding = 0) uniform sampler2D u_EdgesTexture;
layout(set = 2, binding = 0) uniform sampler2D u_AreaTexture;
layout(set = 3, binding = 0) uniform sampler2D u_SearchTexture;

#include <lib/smaa.glsl>

void main() {
    blend = SMAABlendingWeightCalculationPS(v_Texcoord, v_Pixcoord, v_Offset, u_EdgesTexture, u_AreaTexture, u_SearchTexture, vec4(0.0));
}