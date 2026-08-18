#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec2 resolution;
uniform float progress;
uniform float time;
uniform float opacity;
uniform vec3 primaryColor;
uniform vec3 secondaryColor;
uniform vec3 tertiaryColor;
uniform vec3 accentColor;

out vec4 finalColor;

float smoothMinimum(float a, float b, float radius) {
    float blend = clamp(0.5 + 0.5 * (b - a) / radius, 0.0, 1.0);
    return mix(b, a, blend) - radius * blend * (1.0 - blend);
}

float circleDistance(vec2 point, vec2 center, float radius) {
    return length(point - center) - radius;
}

float perceptualLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 preserveLuminance(vec3 color, float targetLuminance) {
    float difference = targetLuminance - perceptualLuminance(color);
    return clamp(color + vec3(difference), 0.0, 1.0);
}

float liquidDistance(vec2 point) {
    float aspect = resolution.x / resolution.y;
    float arrive = smoothstep(0.0, 0.76, progress);

    vec2 centerA = mix(vec2(-aspect - 0.38, 0.52), vec2(-0.38, 0.08), arrive);
    vec2 centerB = mix(vec2(aspect + 0.32, -0.42), vec2(0.40, -0.06), arrive);
    vec2 centerC = mix(vec2(-0.12, -1.42), vec2(0.02, 0.22), arrive);

    float distanceA = circleDistance(point, centerA, mix(0.20, 0.58, arrive));
    float distanceB = circleDistance(point, centerB, mix(0.17, 0.52, arrive));
    float distanceC = circleDistance(point, centerC, mix(0.15, 0.48, arrive));
    float distance = smoothMinimum(distanceA, distanceB, 0.30);
    distance = smoothMinimum(distance, distanceC, 0.28);

    float spread = smoothstep(0.62, 1.0, progress);
    float membraneRadius = mix(0.04, 2.35, spread);
    float membrane = circleDistance(point, vec2(0.0, 0.04), membraneRadius);
    distance = smoothMinimum(distance, membrane, mix(0.16, 0.42, spread));

    float broadRipple = sin(point.x * 6.0 + time * 1.45) *
                        sin(point.y * 5.2 - time * 1.15);
    float fineRipple = sin((point.x + point.y) * 14.0 + time * 1.8) *
                       sin((point.x - point.y) * 9.0 - time * 1.2);
    distance += broadRipple * mix(0.006, 0.013, spread);
    distance += fineRipple * mix(0.0015, 0.0045, spread);
    return distance;
}

vec2 safeUv(vec2 uv) {
    return clamp(uv, vec2(0.002), vec2(0.998));
}

void main() {
    vec2 uv = fragTexCoord;
    float aspect = resolution.x / resolution.y;
    vec2 point = uv * 2.0 - 1.0;
    point.x *= aspect;

    float pixel = 2.0 / resolution.y;
    float distance = liquidDistance(point);
    float gradientX = liquidDistance(point + vec2(pixel, 0.0)) -
                      liquidDistance(point - vec2(pixel, 0.0));
    float gradientY = liquidDistance(point + vec2(0.0, pixel)) -
                      liquidDistance(point - vec2(0.0, pixel));
    vec2 normal = normalize(vec2(gradientX, gradientY) + vec2(0.000001));

    float antialias = 3.0 / resolution.y;
    float mask = 1.0 - smoothstep(-antialias, antialias, distance);
    float edge = 1.0 - smoothstep(antialias, 0.055, abs(distance));

    float distortionStrength = 0.004 + edge * 0.032;
    vec2 distortion = vec2(normal.x / aspect, normal.y) *
                      distortionStrength * mask;
    vec2 surfaceWave = vec2(
        sin(point.y * 12.0 + time * 2.0),
        cos(point.x * 10.0 - time * 1.6)
    ) * (0.0012 + edge * 0.0028) * mask;
    distortion += surfaceWave;

    vec2 dispersionDirection = normalize(distortion + vec2(0.00001));
    vec2 dispersion = dispersionDirection * edge * 0.0060;
    vec2 refractedUv = safeUv(uv + distortion);
    vec3 luminanceSample = texture(texture0, refractedUv).rgb;
    float sourceLuminance = perceptualLuminance(luminanceSample);

    vec3 refracted;
    refracted.r = texture(texture0, safeUv(refractedUv + dispersion)).r;
    refracted.g = texture(texture0, refractedUv).g;
    refracted.b = texture(texture0, safeUv(refractedUv - dispersion)).b;

    vec2 texel = 1.0 / resolution;
    vec2 tangent = vec2(-normal.y, normal.x);
    vec3 softened = texture(texture0, safeUv(refractedUv + tangent * texel * 2.0)).rgb;
    softened += texture(texture0, safeUv(refractedUv - tangent * texel * 2.0)).rgb;
    softened += texture(texture0, safeUv(refractedUv + normal * texel * 1.5)).rgb;
    softened += texture(texture0, safeUv(refractedUv - normal * texel * 1.5)).rgb;
    softened *= 0.25;
    refracted = mix(refracted, softened,
                    (0.06 * mask) + (0.14 * edge));

    float colorPhase = 0.5 + 0.5 * sin(point.x * 1.7 + point.y * 1.3 + time * 0.7);
    vec3 edgeTint = mix(primaryColor, secondaryColor, colorPhase);
    edgeTint = mix(edgeTint, tertiaryColor, 0.28);
    edgeTint = mix(edgeTint, accentColor,
                   0.20 * (0.5 + 0.5 * sin(time * 0.55 + point.y * 1.8)));
    edgeTint = preserveLuminance(edgeTint, sourceLuminance);
    refracted = mix(refracted, edgeTint, 0.11 * edge);
    refracted = preserveLuminance(refracted, sourceLuminance);

    float alpha = mask * (0.48 + edge * 0.12) * opacity;
    finalColor = vec4(refracted, alpha) * fragColor;
}
