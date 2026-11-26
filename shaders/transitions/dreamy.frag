#version 460 core
// Ported from gl-transitions (https://gl-transitions.com), MIT licensed.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress;
uniform sampler2D uFrom;
uniform sampler2D uTo;

out vec4 fragColor;

const float progressEps = 0.0;
vec4 getFromColor(vec2 uv) { return texture(uFrom, vec2(uv.x, 1.0 - uv.y)); }
vec4 getToColor(vec2 uv) { return texture(uTo, vec2(uv.x, 1.0 - uv.y)); }

vec2 dreamOffset(float progress, float x) {
  return vec2(0.0, 0.03 * progress * cos(10.0 * (progress + x)));
}
vec4 transition(vec2 uv) {
  return mix(getFromColor(uv + dreamOffset(uProgress, uv.x)),
             getToColor(uv + dreamOffset(1.0 - uProgress, uv.x)), uProgress);
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  vec2 uv = vec2(frag.x, 1.0 - frag.y);
  fragColor = transition(uv);
}
