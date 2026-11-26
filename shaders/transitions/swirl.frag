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
  float radius = 1.0;
  float t = uProgress;
  vec2 p = uv - vec2(0.5);
  float dist = length(p);
  if (dist < radius) {
    float percent = (radius - dist) / radius;
    float a = (t <= 0.5) ? mix(0.0, 1.0, t / 0.5) : mix(1.0, 0.0, (t - 0.5) / 0.5);
    float theta = percent * percent * a * 8.0 * 3.14159265;
    float s = sin(theta);
    float c = cos(theta);
    p = vec2(dot(p, vec2(c, -s)), dot(p, vec2(s, c)));
  }
  p += vec2(0.5);
  return mix(getFromColor(p), getToColor(p), t);
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  vec2 uv = vec2(frag.x, 1.0 - frag.y);
  fragColor = transition(uv);
}
