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

vec4 transition(vec2 uv) {
  float x = smoothstep(0.0, 1.0, (uProgress * 2.0 + uv.x - 1.0));
  return mix(getFromColor((uv - 0.5) * (1.0 - x) + 0.5),
             getToColor((uv - 0.5) * x + 0.5), x);
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  vec2 uv = vec2(frag.x, 1.0 - frag.y);
  fragColor = transition(uv);
}
