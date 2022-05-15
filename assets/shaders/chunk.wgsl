struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) texCoords: vec2<f32>,
    @location(2) color: vec4<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) texCoords: vec2<f32>,
    @location(1) color: vec4<f32>,
};

struct PushConstants {
    projectionView: mat4x4<f32>,
    chunkPos: vec2<f32>,
};

var<push_constant> pushConstants: PushConstants;

@group(0) @binding(0)
var bTexture: texture_2d<f32>;

@group(0) @binding(1)
var bSampler: sampler;

@stage(vertex)
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;

    out.clip_position = pushConstants.projectionView * vec4<f32>(in.position.x + pushConstants.chunkPos.x, in.position.y, in.position.z + pushConstants.chunkPos.y, 1.0);
    out.texCoords = in.texCoords;
    out.color = in.color;

    return out;
}

@stage(fragment)
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var color = textureSample(bTexture, bSampler, in.texCoords);
    if (color.a <= 0.75) {
        discard;
    }

    return color * in.color;
}