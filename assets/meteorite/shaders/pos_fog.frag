layout(location = 0) in float v_VertexDistance;

layout(location = 0) out vec4 colora;

layout(push_constant, std430) uniform pushConstants {
    mat4 projectionView;
    vec4 color;
    vec4 fogColor;
    float fogStart;
    float fogEnd;
} pc;

vec4 linearFog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    if (vertexDistance <= fogStart) {
        return inColor;
    }

    float fogValue = 1.0;
    if (vertexDistance < fogEnd) {
        fogValue = smoothstep(fogStart, fogEnd, vertexDistance);
    }

    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

void main() {
    colora = linearFog(pc.color, v_VertexDistance, pc.fogStart, pc.fogEnd, pc.fogColor);
}