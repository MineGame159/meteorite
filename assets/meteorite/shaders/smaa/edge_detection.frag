#version 460

layout(location = 0) out vec4 edge;

layout(location = 0) in vec2 v_Texcoord;
layout(location = 1) in vec4[3] v_Offset;

layout(set = 1, binding = 0) uniform sampler2D u_Texture;

#include <lib/smaa.glsl>

void main() {
    #if defined(SMAA_EDGE_DETECTION_LUMA)
        edge = vec4(SMAALumaEdgeDetectionPS(v_Texcoord, v_Offset, u_Texture), 0.0, 0.0);
    #elif defined(SMAA_EDGE_DETECTION_COLOR)
        edge = vec4(SMAAColorEdgeDetectionPS(v_Texcoord, v_Offset, u_Texture), 0.0, 0.0);
    #else
        #error You must set either SMAA_EDGE_DETECTION_LUMA or SMAA_EDGE_DETECTION_COLOR
    #endif
}