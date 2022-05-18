struct VertexInput {
    @location(0) position: vec3<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) vertexDistance: f32,
};

struct PushConstants {
    projectionView: mat4x4<f32>,
    color: vec4<f32>,
    fogColor: vec4<f32>,
    fogStart: f32,
    fogEnd: f32,
};

var<push_constant> pushConstants: PushConstants;

fn fog_distance(modelViewMat: mat4x4<f32>, pos: vec3<f32>, shape: i32) -> f32 {
    if (shape == 0) {
        return length((modelViewMat * vec4<f32>(pos, 1.0)).xyz);
    }
    else {
        let distXZ = length((modelViewMat * vec4<f32>(pos.x, 0.0, pos.z, 1.0)).xyz);
        let distY = length((modelViewMat * vec4<f32>(0.0, pos.y, 0.0, 1.0)).xyz);
        return max(distXZ, distY);
    }
}

fn linear_fog(inColor: vec4<f32>, vertexDistance: f32, fogStart: f32, fogEnd: f32, fogColor: vec4<f32>) -> vec4<f32> {
    if (vertexDistance <= fogStart) {
        return inColor;
    }

    var fogValue = 1.0;
    if (vertexDistance < fogEnd) {
        fogValue = smoothStep(fogStart, fogEnd, vertexDistance);
    }

    return vec4<f32>(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

@stage(vertex)
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;

    out.clip_position = pushConstants.projectionView * vec4<f32>(in.position, 1.0);
    out.vertexDistance = fog_distance(pushConstants.projectionView, in.position, 1);

    return out;
}

@stage(fragment)
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return linear_fog(pushConstants.color, in.vertexDistance, pushConstants.fogStart, pushConstants.fogEnd, pushConstants.fogColor);
}