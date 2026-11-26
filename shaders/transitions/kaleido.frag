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
  float speed = 1.0;
  float angle = 1.0;
  float power = 1.5;
  vec2 q = uv;
  vec2 p = uv;
  float t = pow(uProgress, power) * speed;
  p = p - 0.5;
  for (int i = 0; i < 7; i++) {
    p = vec2(sin(t) * p.x + cos(t) * p.y, sin(t) * p.y - cos(t) * p.x);
    t += angle;
    p = abs(mod(p, 2.0) - 1.0);
  }
  p = abs(mod(p, 1.0));
  return mix(mix(getFromColor(q), getToColor(q), uProgress),
             mix(getFromColor(p), getToColor(p), uProgress),
             1.0 - 2.0 * abs(uProgress - 0.5));
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  vec2 uv = vec2(frag.x, 1.0 - frag.y);
  fragColor = transition(uv);
}
