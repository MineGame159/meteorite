vec2 noiseScale = api_Resolution / 4.0;

const int kernelSize = 64;
const float radius = 0.5;
const float bias = 0.025;

#ifdef IDK
    float linearizeDepth(float depth) {
        return api_ProjectionB / (depth - api_ProjectionA);
    }

    vec3 reconstructPosition(vec2 texCoord) {
        float depth = linearizeDepth(texture(DEPTH_SAMPLER, texCoord).x);
        return vec3(v_Position.xy * depth, -depth);
    }
#endif

float ssao(vec2 texCoord) {
    #ifdef IDK
        ivec2 fragCoord = ivec2(gl_FragCoord.xy);

        vec3 fragPos   = reconstructPosition(texCoord);
        vec3 normal    = texture(NORMAL_SAMPLER, texCoord).xyz;
        vec3 randomVec = texture(NOISE_SAMPLER, texCoord * noiseScale).xyz;

        vec3 tangent   = normalize(randomVec - normal * dot(randomVec, normal));
        vec3 bitangent = cross(normal, tangent);
        mat3 TBN       = mat3(tangent, bitangent, normal);

        float occlusion = 0.0;
        for (int i = 0; i < kernelSize; ++i) {
            // get sample position
            vec3 samplePos = TBN * omg.samples[i].xyz; // from tangent to view-space
            samplePos = fragPos + samplePos * radius;
            
            vec4 offset = vec4(samplePos, 1.0);
            offset      = api_Projection * offset; // from view to clip-space
            offset.xyz /= offset.w;                // perspective divide
            offset.xyz  = offset.xyz * 0.5 + 0.5;  // transform to range 0.0 - 1.0

            offset.y = 1.0 - offset.y;
            float sampleDepth = -linearizeDepth(texture(DEPTH_SAMPLER, offset.xy).x);

            float rangeCheck = smoothstep(0.0, 1.0, radius / abs(fragPos.z - sampleDepth));
            occlusion += (sampleDepth >= samplePos.z + bias ? 1.0 : 0.0) * rangeCheck;
        }

        return 1.0 - (occlusion / kernelSize);
    #else
        vec2 texel = 1.0 / api_Resolution;
        float result = 0.0;

        // Workaround around (probably) Naga issue where variables are put into the function scope and not reassigned automatically at the end of the loop
        int x = -2;
        while (x < 2) {
            int y = -2;

            while (y < 2) {
                result += texture(SSAO_SAMPLER, texCoord + vec2(x, y) * texel).r;
                y++;
            }

            y = -2;
            x++;
        }

        return result / (4.0 * 4.0);
    #endif
}