layout(location = 0) in vec2 v_TexCoord;
layout(location = 1) in vec4 v_Color;

layout(location = 0) out vec4 color;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
} pc;

layout(set = 0, binding = 0) uniform texture2D u_Texture;
layout(set = 0, binding = 1) uniform sampler u_Sampler;

void main() {
    color = texture(sampler2D(u_Texture, u_Sampler), v_TexCoord) * v_Color;
}