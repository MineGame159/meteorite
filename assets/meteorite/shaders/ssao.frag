#version 460

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;

layout(location = 0) out vec4 color;

#include <lib/api.glsl>

layout(set = 1, binding = 0) uniform sampler2D u_NormalTexture;
#define NORMAL_SAMPLER u_NormalTexture

layout(set = 2, binding = 0) uniform sampler2D u_DepthTexture;
#define DEPTH_SAMPLER u_DepthTexture

layout(set = 3, binding = 0) uniform Samples {
    vec4 samples[64];
} omg;

layout(set = 3, binding = 1) uniform sampler2D u_NoiseTexture;
#define NOISE_SAMPLER u_NoiseTexture

#define IDK
#include <lib/ssao.glsl>

void main() {
    color = vec4(ssao(v_TexCoord));
}