layout(location = 0) in vec3 position;
layout(location = 1) in vec4 color;

layout(location = 0) out vec4 v_Color;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
} pc;

void main() {
    gl_Position = pc.projectionView * vec4(position, 1.0);
    v_Color = color;
}