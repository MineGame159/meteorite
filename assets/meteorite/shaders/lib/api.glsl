layout(set = 0, binding = 0, std430) uniform FrameUniforms {
    mat4 projection;
    mat4 view;
    mat4 projectionView;

    vec2 resolution;
} frame;

#define api_Projection frame.projection
#define api_View frame.view
#define api_ProjectionView frame.projectionView

#define api_Resolution frame.resolution