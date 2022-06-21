layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texCoord;

layout(location = 0) out vec2 v_TexCoord;

layout(push_constant, std430) uniform pushConstants {
    vec2 size;
} pc;

void main() {
    gl_Position = vec4(position, 1.0);
    v_TexCoord = texCoord;
}