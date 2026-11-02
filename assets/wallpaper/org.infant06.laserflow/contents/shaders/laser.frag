#version 440
// Port of ReactBits "Laser Flow" (https://reactbits.dev/c/animations/laser-flow)
// to a Qt Quick ShaderEffect. Renders the settled state (after the intro),
// without mouse lens / reveal image.
//
// Original effect: React Bits LaserFlow, Copyright (c) 2026 David Haz.
// Licensed under MIT + Commons Clause License Condition v1.0
// https://github.com/DavidHDev/react-bits/blob/main/LICENSE.md

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uScale;
    float uBeamX;
    vec4 uResolution;  // x,y = size (px), z = beam front (px), w = surface radius (px)
    vec4 uSurface;     // left, top, right, bottom (px)
    vec4 uAmount;      // intensity, fog, dust, streaks
    vec4 uShape;       // beamWidth, flare, spread, spill
    vec4 uExtra;       // pulse, dots, seedX, seedY
    vec4 uBg;          // background colour
    vec4 uT0;  vec4 uT1;  vec4 uT2;  vec4 uT3;
    vec4 uT4;  vec4 uT5;  vec4 uT6;  vec4 uT7;
    vec4 uT8;  vec4 uT9;  vec4 uT10; vec4 uT11;
    vec4 uT12; vec4 uT13; vec4 uT14; vec4 uT15;
};

#define BEAM     uT0.rgb
#define LEFT     uT1.rgb
#define RIGHT    uT2.rgb
#define CYAN     uT3.rgb
#define PINK     uT4.rgb
#define LILAC    uT5.rgb
#define SKY      uT6.rgb
#define PURPLE   uT7.rgb
#define DEEP     uT8.rgb
#define MIST     uT9.rgb
#define NAVY     uT10.rgb
#define WARM     uT11.rgb
#define EMBER    uT12.rgb
#define WHITE    uT13.rgb
#define HAZE     uT14.rgb
#define LAVENDER uT15.rgb

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = m * p;
        a *= 0.5;
    }
    return v;
}

float sq(float x) { return x * x; }

float roundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec3 spill(float e, float fall, float strength, float front, float t, out vec3 glow) {
    glow = vec3(0.0);
    if (strength < 0.0005) return vec3(0.0);
    float f = max(fall, 0.0);
    float d = max(e, 0.0);
    float u = d / (6.0 + 0.28 * f);
    float start = smoothstep(-6.0, 12.0, fall);
    float fade = exp(-sq(max(f - 125.0, 0.0) / 40.0));
    float streak = 0.88 + 0.24 * noise(vec2(u * 6.0, f / 22.0 - t * 1.7));
    float bright = pow(strength, 1.5);
    float soft = sqrt(strength);
    float warmth = smoothstep(90.0, 130.0, f);
    vec3 coreK = mix(WHITE, WARM, warmth * exp(-d / 9.0));
    float core = mix(9.0, 2.6, warmth) * exp(-sq(d / (3.5 + 0.04 * f))) * exp(-sq(max(f - 130.0, 0.0) / 38.0));
    float wall = 24.0 * exp(-sq(d / 1.1)) * exp(-sq(max(f - 100.0, 0.0) / 30.0));
    float bandCenter = 0.7 - 0.3 * smoothstep(30.0, 110.0, f);
    float offset = u - bandCenter;
    float decay = (1.05 - bandCenter) / 1.31;
    float profile = offset < 0.0 ? exp(-sq(offset / 0.3)) : exp(-offset / decay);
    profile *= 1.0 - smoothstep(1.0, 1.4, u);
    vec3 bandA = mix(CYAN, PINK, smoothstep(50.0, 75.0, f));
    bandA = mix(bandA, LILAC, smoothstep(100.0, 125.0, f));
    vec3 bandB = mix(SKY, PURPLE, smoothstep(50.0, 75.0, f));
    vec3 fanK = mix(bandA, bandB, smoothstep(0.06, 0.18, offset));
    fanK = mix(fanK, DEEP, smoothstep(0.22, 0.42, offset));
    vec3 thread = WHITE * wall * bright + coreK * core * streak * bright;
    glow += fanK * 4.5 * profile * fade * streak * bright;
    glow += MIST * 0.7 * exp(-max(u - 1.0, 0.0) / 0.9) * smoothstep(0.7, 1.2, u) * fade * soft;
    glow += EMBER * 0.35 * exp(-sq((f - 165.0) / 22.0)) * exp(-d / 25.0) * bright;
    float lag = u * (6.0 + 0.28 * f) * 0.35;
    float reveal = 1.0 - smoothstep(front - 70.0, front + 8.0, f + lag);
    glow *= start * reveal;
    return thread * start * reveal;
}

vec3 easeLight(vec3 light, float amount) {
    return -log(max(1.0 - amount * (1.0 - exp(-light)), vec3(0.0001)));
}

void main() {
    vec2 frag = qt_TexCoord0 * uResolution.xy;   // top-left origin, logical px
    vec2 p = frag / uScale;
    float t = uTime;

    // Settled intro state
    const float bloom = 1.0;
    const float run = 100000.0;
    const float beadK = 0.0;
    const float pourFront = 1000.0;
    const float pourFill = 1.0;
    const float atmosphere = 1.0;

    float bx = uBeamX / uScale;
    float sl = uSurface.x / uScale;
    float sy = uSurface.y / uScale;
    float sr = uSurface.z / uScale;
    float sb = uSurface.w / uScale;
    float radius = uResolution.w / uScale;

    float dx = p.x - bx;
    float adx = abs(dx);
    float h = sy - p.y;
    float hp = max(h, 0.0);
    float above = smoothstep(-0.5, 0.5, h);
    float side = smoothstep(-24.0, 24.0, dx);
    vec3 sideK = mix(mix(LAVENDER, LEFT, smoothstep(40.0, 140.0, adx)), RIGHT, side);

    float beamWidth = uShape.x;
    float flare = uShape.y;
    float spread = 250.0 * uShape.z;
    float reachL = max(bx - sl, 1.0);
    float reachR = max(sr - bx, 1.0);
    float reach = dx < 0.0 ? reachL : reachR;
    float layerLen = clamp(0.29 * reach, 20.0, 100.0) * sqrt(uShape.z);

    float runMask = 1.0 - smoothstep(run - 34.0, run + 6.0, adx);
    float bead = exp(-sq((adx - run + 16.0) / (18.0 + 0.04 * run))) * beadK;
    float flowMask = (1.0 - smoothstep(0.75 * spread, 1.1 * spread, adx)) * runMask;
    float edgeMask = (1.0 - smoothstep(0.8 * spread, 1.25 * spread, adx)) * runMask;

    vec2 center = vec2((sl + sr) * 0.5, (sy + sb) * 0.5);
    vec2 halfSize = vec2((sr - sl) * 0.5, (sb - sy) * 0.5);
    float sd = roundBox(p - center, halfSize, radius);
    float outline = max(sd, 0.0);
    float below = max(p.y - sy - radius, 0.0);
    float hug = smoothstep(-0.5, 0.5, sd) * exp(-sq(below / 14.0));
    float hugWide = smoothstep(-0.5, 0.5, sd) * exp(-sq(below / 40.0));

    vec3 col = vec3(0.0);
    float breathe = 1.0 + uExtra.x * (0.12 * sin(t * 1.5708) + 0.08 * (noise(vec2(t * 0.5, 3.0)) - 0.5));
    float front = uResolution.z / uScale;
    float drop = smoothstep(front + 10.0, front - 110.0, p.y);
    float top = mix(0.3, 1.0, smoothstep(0.0, 0.3 * sy, p.y));

    // Beam
    float beamCore = 24.0 * exp(-adx / (2.0 * beamWidth));
    float beamHalo = 1.3 * exp(-adx / (6.0 * beamWidth)) + 0.3 * exp(-adx / (22.0 * beamWidth));
    vec3 haloK = mix(BEAM, sideK, exp(-hp / 80.0));
    col += (BEAM * beamCore + haloK * beamHalo) * top * above * drop;

    // Impact skirt and surface layer
    float psi = adx * (outline + 1.0);
    float rise = max(hp - 17.9 * flare, 0.0);
    float skirtAmp = 16.6 * (exp(-sq(rise / (11.8 * flare))) + 0.3 * exp(-rise / (60.0 * flare)));
    float skirtSpread = mix(134.0, 155.0, side) * breathe * flare * flare;
    float skirt = skirtAmp * exp(-psi / skirtSpread)
                * exp(-sq(adx / (max(layerLen, 60.0 * sqrt(uShape.z)) * 1.48))) * hug;
    col += sideK * skirt * flowMask;
    float layer = 12.0 * exp(-adx / layerLen) * exp(-outline / (0.19 * layerLen)) * (1.0 + 0.4 * bead);
    col += sideK * layer * hug * flowMask;

    float washMask = smoothstep(sl - 60.0, sl + 6.0, p.x) * (1.0 - smoothstep(sr - 6.0, sr + 45.0, p.x));
    float wash = 1.4 * exp(-adx / 100.0) * exp(-outline / 30.0);
    col += mix(BEAM, sideK, 0.25) * wash * hugWide * washMask * flowMask;
    float highWash = 0.7 * exp(-adx / 140.0) * exp(-outline / 60.0);
    col += mix(BEAM, NAVY, 0.5) * highWash * hugWide * washMask * runMask;

    // Flow lines
    float sideSign = dx < 0.0 ? 0.0 : 1.0;
    float along = 0.5 * log((hp + 1.0) / (adx + 1.0));
    float lineScale = 6.0;
    float lp = log(max(psi, 1.0) / (120.0 * flare * flare)) * lineScale;
    float lineIndex = floor(lp) + sideSign * 97.0;
    float wobble = 0.22 * (noise(vec2(lineIndex * 3.7, t * 0.4 + along)) - 0.5);
    float lf = fract(lp + wobble) - 0.5;
    float gradient = lineScale * length(vec2(hp + 1.0, adx)) / max(psi, 1.0) / uScale;
    float halfWidth = max(0.35 * gradient, 0.0001);
    float drawWidth = max(halfWidth, 0.6 * gradient);
    float lineShape = exp(-lf * lf / (drawWidth * drawWidth)) * (halfWidth / drawWidth);
    float lineOn = step(0.3, hash(vec2(lineIndex, 1.3)));
    float lineFlow = smoothstep(0.25, 0.85, noise(vec2(lineIndex * 5.3 + 2.0, along * 3.0 + t * 1.1)));
    float flareArea = 120.0 * flare * flare;
    float lineEnvelope = smoothstep(0.85 * flareArea, 1.4 * flareArea, psi)
                       * (1.0 - smoothstep(3.2 * flareArea, 7.5 * flareArea, psi));
    lineEnvelope *= exp(-adx / (layerLen * 1.5)) * hug * flowMask * (1.0 - smoothstep(35.0 * flare, 80.0 * flare, hp));
    float lineBright = mix(0.35, 1.0, hash(vec2(lineIndex, 4.0)));
    col += mix(sideK, WHITE, 0.6) * lineShape * lineOn * lineFlow * lineEnvelope * lineBright * 2.6 * uAmount.w;

    // Surface edge
    float edgeGlow = 22.8 * exp(-sq(adx / (150.0 * uShape.z))) * edgeMask * (1.0 + 0.9 * bead);
    float onTop = 1.0 - smoothstep(sy + radius, sy + radius + 10.0, p.y);
    float edgeLine = (exp(-sq(max(sd, 0.0) / 0.9)) + 0.12 * exp(-max(sd, 0.0) / 3.0)) * edgeGlow * onTop;
    col += mix(sideK, WHITE, 0.6) * edgeLine;

    // Pour over the corners
    float pour = uShape.w;
    float baseline = exp(-sq(130.0 / 150.0));
    float strengthR = exp(-sq(reachR / (150.0 * uShape.z))) * (1.0 - smoothstep(0.8 * spread, 1.25 * spread, reachR)) / baseline * pour;
    float strengthL = exp(-sq(reachL / (150.0 * uShape.z))) * (1.0 - smoothstep(0.8 * spread, 1.25 * spread, reachL)) / baseline * pour;
    float fallY = p.y - sy - 0.3 * radius;
    float rightHalf = smoothstep(center.x - 4.0, center.x + 4.0, p.x);
    float haloR = exp(-length(p - vec2(sr - 0.3 * radius, sy + 0.3 * radius)) / 40.0) * sqrt(strengthR);
    float haloL = exp(-length(p - vec2(sl + 0.3 * radius, sy + 0.3 * radius)) / 40.0) * sqrt(strengthL);
    vec3 glowR;
    vec3 glowL;
    col += spill(sd, fallY, strengthR, pourFront, t, glowR) * rightHalf;
    col += spill(sd, fallY, strengthL, pourFront, t, glowL) * (1.0 - rightHalf);
    col += easeLight(glowR * rightHalf + NAVY * 0.9 * haloR, pourFill);
    col += easeLight(glowL * (1.0 - rightHalf) + NAVY * 0.9 * haloL, pourFill);

    // Fog
    float fogAmount = uAmount.y * atmosphere;
    float near = exp(-adx / 150.0);
    float envelope = near * (0.3 + 0.4 * exp(-hp / 50.0) + 1.2 * exp(-p.y / 120.0));
    if (fogAmount > 0.001 && h > -2.0 && envelope * max(0.25, 6.0 * exp(-adx / 50.0)) > 0.002) {
        vec2 fq = vec2(dx / 1.7, h) / 85.0 + vec2(t * 0.012, -t * 0.03) + uExtra.zw;
        vec2 fw = vec2(fbm(fq * 1.3 + vec2(1.7, 9.2) + t * 0.03), fbm(fq * 1.3 + vec2(8.3, 2.8) - t * 0.025));
        float cloud = fbm(fq + 1.4 * fw);
        float density = smoothstep(0.5, 0.78, cloud);
        float lit = exp(-adx / 50.0);
        float fogMask = smoothstep(-2.0, 20.0, h);
        float reached = smoothstep(front + 80.0, front - 40.0, p.y);
        vec3 fog = (HAZE * 0.45 + BEAM * 6.0 * lit * reached) * density * envelope * fogMask;
        float surfaceLit = exp(-adx / (layerLen * 1.3)) * exp(-outline / 28.0) * hugWide * flowMask * washMask;
        fog += sideK * 2.2 * surfaceLit * (smoothstep(0.38, 0.72, cloud) - 0.35) * fogMask;
        float smoke = smoothstep(0.3, 0.75, cloud);
        fog += BEAM * 0.35 * exp(-adx / (22.0 * beamWidth)) * (0.35 + 0.9 * smoke) * fogMask * top * drop;
        col += fog * fogAmount;
    }

    // Dot grid
    float haze = col.b;
    float dotGrid = 1.0 - smoothstep(0.16, 0.32, length(fract(frag / 3.0) - 0.5));
    col += BEAM * dotGrid * clamp(haze, 0.0, 1.5) * (1.0 - smoothstep(1.5, 4.0, haze)) * 0.18 * uExtra.y;

    // Dust and glitter
    float dustAmount = uAmount.z;
    if (dustAmount > 0.001) {
        float dustLp = log(max(psi, 1.0) / (120.0 * flare * flare)) * 2.2;
        vec2 flowCell = vec2(dustLp / 1.1, (along + t * 0.22) / 0.06);
        vec2 cellId = floor(flowCell) + vec2(sideSign * 131.0, 0.0);
        vec2 cellJitter = vec2(hash(cellId + 1.7), hash(cellId + 8.3));
        vec2 particleFlow = (floor(flowCell) + 0.1 + cellJitter * 0.8) * vec2(1.1, 0.06);
        float particlePsi = 120.0 * flare * flare * exp(particleFlow.x / 2.2);
        float particleAlong = particleFlow.y - t * 0.22;
        float particleX = sqrt(particlePsi * exp(-2.0 * particleAlong)) - 1.0;
        float particleH = sqrt(particlePsi * exp(2.0 * particleAlong)) - 1.0;
        float particleDist = length(vec2(adx - particleX, hp - particleH)) * uScale;
        float particleOn = step(0.62, hash(cellId + 3.1));
        float particleTwinkle = 0.5 + 0.5 * sin(t * 5.0 + hash(cellId + 9.2) * 6.283);
        float dustZone = exp(-sq(log(max(psi, 1.0) / (200.0 * flare * flare)) / 0.55)) * hug * flowMask * smoothstep(0.0, 6.0, outline);
        col += WHITE * exp(-particleDist * particleDist / 0.3) * particleOn * particleTwinkle * dustZone * 3.0 * dustAmount;

        vec2 glitterCell = vec2(dx / 3.0, (p.y - t * 26.0) / 9.0);
        vec2 glitterId = floor(glitterCell);
        vec2 glitterJitter = vec2(hash(glitterId + 4.4), hash(glitterId + 2.9));
        vec2 glitterPos = (glitterId + 0.15 + glitterJitter * 0.7) * vec2(3.0, 9.0);
        float glitterDist = length(vec2(dx, p.y - t * 26.0) - glitterPos) * uScale;
        float glitterOn = step(0.7, hash(glitterId + 6.6));
        float glitterTwinkle = 0.5 + 0.5 * sin(t * 6.0 + hash(glitterId + 1.1) * 6.283);
        float glitterZone = exp(-adx / (5.0 * beamWidth)) * smoothstep(1.5, 4.0, adx / beamWidth)
                          * above * smoothstep(25.0, 70.0, hp) * top * drop;
        col += WHITE * exp(-glitterDist * glitterDist / 0.25) * glitterOn * glitterTwinkle * glitterZone * 2.2 * dustAmount * atmosphere;
    }

    col *= uAmount.x;
    col *= smoothstep(-0.75, 0.25, sd * uScale);

    vec3 emit = 1.0 - exp(-col);
    float peak = max(emit.r, max(emit.g, emit.b));
    // Premultiplied "over" onto the background colour
    vec3 outCol = emit + uBg.rgb * (1.0 - peak);
    fragColor = vec4(outCol, 1.0) * qt_Opacity;
}
