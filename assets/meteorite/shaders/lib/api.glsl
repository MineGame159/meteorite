layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 projection;
    mat4 inverseProjection;
    mat4 view;
    mat4 inverseView;
    mat4 projectionView;

    float projectionA;
    float projectionB;

    vec2 resolution;
} frame;

#define api_Projection frame.projection
#define api_InverseProjection frame.inverseProjection
#define api_View frame.view
#define api_InverseView frame.inverseView
#define api_ProjectionView frame.projectionView

#define api_ProjectionA frame.projectionA
#define api_ProjectionB frame.projectionB

#define api_Resolution frame.resolution