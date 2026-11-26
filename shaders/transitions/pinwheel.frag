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
  float speed = 2.0;
  float circPos = atan(uv.y - 0.5, uv.x - 0.5) + uProgress * speed;
  float modPos = mod(circPos, 3.1415 / 4.0);
  float s = sign(uProgress - modPos);
  return mix(getToColor(uv), getFromColor(uv), step(s, 0.5));
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  vec2 uv = vec2(frag.x, 1.0 - frag.y);
  fragColor = transition(uv);
}
