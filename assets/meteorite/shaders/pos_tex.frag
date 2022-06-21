layout(location = 0) in vec2 v_TexCoord;

layout(location = 0) out vec4 colora;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
    vec4 color;
} pc;

layout(set = 0, binding = 0) uniform texture2D u_Texture;
layout(set = 0, binding = 1) uniform sampler u_Sampler;

void main() {
    colora = texture(sampler2D(u_Texture, u_Sampler), v_TexCoord) * pc.color;
}