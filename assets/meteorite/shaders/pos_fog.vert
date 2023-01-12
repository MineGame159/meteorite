#version 460

layout(location = 0) in vec3 position;

layout(location = 0) out float v_VertexDistance;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
    vec4 color;
    vec4 fogColor;
    float fogStart;
    float fogEnd;
} pc;

float fogDistance(mat4 modelViewMat, vec3 pos, int shape) {
    if (shape == 0) {
        return length((modelViewMat * vec4(pos, 1.0)).xyz);
    }
    else {
        float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
        float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
        return max(distXZ, distY);
    }
}

void main() {
    gl_Position = pc.projectionView * vec4(position, 1.0);
    v_VertexDistance = fogDistance(pc.projectionView, position, 1);
}