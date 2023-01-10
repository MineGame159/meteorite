#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texCoord;

layout(location = 0) out vec2 v_TexCoord;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
    vec4 color;
} pc;

void main() {
    gl_Position = pc.projectionView * vec4(position, 1.0);
    v_TexCoord = texCoord;
}