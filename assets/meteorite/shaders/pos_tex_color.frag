#version 460

layout(location = 0) in vec2 v_TexCoord;
layout(location = 1) in vec4 v_Color;

layout(location = 0) out vec4 color;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
} pc;

layout(set = 0, binding = 0) uniform sampler2D u_Texture;

void main() {
    color = texture(u_Texture, v_TexCoord) * v_Color;
}