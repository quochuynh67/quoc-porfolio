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
  float amplitude = 100.0;
  float speed = 50.0;
  vec2 dir = uv - vec2(0.5);
  float dist = length(dir);
  vec2 offset = dir * (sin(uProgress * dist * amplitude - uProgress * speed) + 0.5) / 30.0;
  return mix(getFromColor(uv + offset), getToColor(uv),
             smoothstep(0.2, 1.0, uProgress));
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  vec2 uv = vec2(frag.x, 1.0 - frag.y);
  fragColor = transition(uv);
}
