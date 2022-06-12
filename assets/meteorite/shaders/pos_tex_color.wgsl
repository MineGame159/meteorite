struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) texCoord: vec2<f32>,
    @location(2) color: vec4<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) texCoord: vec2<f32>,
    @location(1) color: vec4<f32>,
};

struct PushConstants {
    projectionView: mat4x4<f32>,
};

var<push_constant> pushConstants: PushConstants;

@group(0) @binding(0)
var bTexture: texture_2d<f32>;

@group(0) @binding(1)
var bSampler: sampler;

@stage(vertex)
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;

    out.clip_position = pushConstants.projectionView * vec4<f32>(in.position, 1.0);
    out.texCoord = in.texCoord;
    out.color = in.color;

    return out;
}

@stage(fragment)
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(bTexture, bSampler, in.texCoord) * in.color;
}