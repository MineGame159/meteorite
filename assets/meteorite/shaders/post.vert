#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texcoord;

layout(location = 0) out vec2 v_Texcoord;

#ifdef SMAA_ENABLED
    layout(location = 1) out vec4 v_Offset;

    #include <lib/smaa.glsl>
#endif

void main() {
    gl_Position = vec4(position, 1.0);
    v_Texcoord = texcoord;

    #ifdef SMAA_ENABLED
        SMAANeighborhoodBlendingVS(texcoord, v_Offset);
    #endif
}