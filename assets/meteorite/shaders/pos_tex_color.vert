#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in vec4 color;

layout(location = 0) out vec2 v_TexCoord;
layout(location = 1) out vec4 v_Color;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
} pc;

void main() {
    gl_Position = pc.projectionView * vec4(position, 1.0);
    v_TexCoord = texCoord;
    v_Color = color;
}