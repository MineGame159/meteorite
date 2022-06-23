layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;

layout(location = 0) out vec4 color;

#include lib/api

layout(set = 1, binding = 0) uniform texture2D u_NormalTexture;
layout(set = 1, binding = 1) uniform sampler u_NormalSampler;
#define NORMAL_SAMPLER sampler2D(u_NormalTexture, u_NormalSampler)

layout(set = 2, binding = 0) uniform texture2D u_DepthTexture;
layout(set = 2, binding = 1) uniform sampler u_DepthSampler;
#define DEPTH_SAMPLER sampler2D(u_DepthTexture, u_DepthSampler)

layout(set = 3, binding = 0, std430) uniform Samples {
    vec4 samples[64];
} omg;

layout(set = 3, binding = 1) uniform texture2D u_NoiseTexture;
layout(set = 3, binding = 2) uniform sampler u_NoiseSampler;
#define NOISE_SAMPLER sampler2D(u_NoiseTexture, u_NoiseSampler)

#define IDK
#include lib/ssao

void main() {
    color = vec4(ssao(v_TexCoord));
}