struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) texCoords: vec2<f32>,
    @location(2) color: vec4<f32>,
    @location(3) texture: vec2<u32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv1: vec2<f32>,
    @location(1) uv2: vec2<f32>,
    @location(2) blend: f32,
    @location(3) color: vec4<f32>,
};

struct Texture {
    uv1: vec2<f32>,
    uv2: vec2<f32>,
    size: f32,
    blend: f32,
};

struct PushConstants {
    projectionView: mat4x4<f32>,
    chunkPos: vec3<f32>,
};

var<push_constant> pushConstants: PushConstants;

@group(0) @binding(0)
var bTexture: texture_2d<f32>;

@group(0) @binding(1)
var bSampler: sampler;

@group(1) @binding(0)
var<storage> textures: array<Texture>;

@stage(vertex)
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;

    let texture = textures[in.texture.x];
    let texCoords = in.texCoords * texture.size;

    out.clip_position = pushConstants.projectionView * vec4<f32>(in.position + pushConstants.chunkPos, 1.0);
    out.color = in.color;
    out.uv1 = texCoords + texture.uv1;
    out.uv2 = texCoords + texture.uv2;
    out.blend = texture.blend;

    return out;
}

@stage(fragment)
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let color1 = textureSample(bTexture, bSampler, in.uv1);
    let color2 = textureSample(bTexture, bSampler, in.uv2);

    let color = mix(color1, color2, in.blend);
    if (color.a <= 0.75) {
        discard;
    }

    return color * in.color;
}