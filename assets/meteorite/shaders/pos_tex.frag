#version 460

layout(location = 0) in vec2 v_TexCoord;

layout(location = 0) out vec4 colora;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
    vec4 color;
} pc;

layout(set = 0, binding = 0) uniform sampler2D u_Texture;

void main() {
    colora = texture(u_Texture, v_TexCoord) * pc.color;
}