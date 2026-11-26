#version 460 core
// gl-transitions (https://gl-transitions.com) — DiamondWipe by gre, MIT.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress;
uniform sampler2D uFrom;
uniform sampler2D uTo;

out vec4 fragColor;

float progress = 0.0;
float ratio = 1.0;
vec4 getFromColor(vec2 uv) { return texture(uFrom, vec2(uv.x, 1.0 - uv.y)); }
vec4 getToColor(vec2 uv) { return texture(uTo, vec2(uv.x, 1.0 - uv.y)); }

// Author: gre
// License: MIT
// Description: A soft-edged diamond grows from the center to reveal the incoming image
// Tags: shape, wipe, iris

// @param Center of the diamond
const vec2 center = vec2(0.5);
// @range(0, 0.5) Softness of the diamond's edge
const float smoothness = 0.03;

vec4 transition (vec2 uv) {
  // Measured in square pixels, so the diamond is not stretched
  vec2 d = abs(uv - center) * vec2(ratio, 1.0);
  vec2 far = max(center, 1.0 - center) * vec2(ratio, 1.0);
  float dist = (d.x + d.y) / (far.x + far.y);
  float s = max(smoothness, 0.001);
  float m = smoothstep(0.0, s, progress * (1.0 + s) - dist);
  return mix(getFromColor(uv), getToColor(uv), m);
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
