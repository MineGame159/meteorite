struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) texCoord: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) texCoord: vec2<f32>,
    @location(1) diffuse: f32,
};

struct PushConstants {
    projectionView: mat4x4<f32>,
};

var<push_constant> pushConstants: PushConstants;

@group(0) @binding(0)
var bTexture: texture_2d<f32>;

@group(0) @binding(1)
var bSampler: sampler;

let LIGHT1      = vec3<f32>( 0.104196384,  0.947239857, -0.303116754);
let LIGHT2      = vec3<f32>(-0.104196384,  0.947239857,  0.303116754);
let LIGHT2_DARK = vec3<f32>(-0.104196384, -0.947239857,  0.303116754);

fn diffuse(normal: vec3<f32>) -> f32 {
    let l1 = max(0.0, dot(LIGHT1, normal));
    let l2 = max(0.0, dot(LIGHT2, normal));

    return 0.5 + min(0.5, l1 + l2);
}

@stage(vertex)
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;

    out.clip_position = pushConstants.projectionView * vec4<f32>(in.position, 1.0);
    out.texCoord = in.texCoord;
    out.diffuse = diffuse(in.normal);

    return out;
}

@stage(fragment)
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let color = textureSample(bTexture, bSampler, in.texCoord);

    if (color.a <= 0.75) {
        discard;
    }

    return color * vec4<f32>(in.diffuse, in.diffuse, in.diffuse, 1.0);
}