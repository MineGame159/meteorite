#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texCoords;
layout(location = 2) in vec4 color;
layout(location = 3) in uvec2 texture;
layout(location = 4) in vec4 normal;

layout(location = 0) out vec2 v_Uv1;
layout(location = 1) out vec2 v_Uv2;
layout(location = 2) out float v_Blend;
layout(location = 3) out vec4 v_Color;
layout(location = 4) out vec4 v_Normal;

#include <lib/api.glsl>

layout(push_constant, std430) uniform pushConstants {
    vec3 chunkPos;
} pc;

struct Texture {
    vec2 uv1;
    vec2 uv2;
    float size;
    float blend;
};

layout(set = 2, binding = 0, std430) buffer TextureBuffer {
    Texture textures[];
};

void main() {
    Texture tex = textures[texture.x];
    vec2 texCoord = texCoords * tex.size;

    gl_Position = api_ProjectionView * vec4(position + pc.chunkPos, 1.0);
    v_Uv1 = texCoord + tex.uv1;
    v_Uv2 = texCoord + tex.uv2;
    v_Blend = tex.blend;
    v_Color = color;
    v_Normal = api_InverseView * normal;
}