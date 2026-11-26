#version 460 core
// gl-transitions (https://gl-transitions.com) — Fisheye by gre, MIT.
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
// Description: The outgoing image bulges toward the viewer through a strong fisheye lens, then the incoming one flattens back into place
// Tags: lens, distort, zoom, blend
// Preview: 0.5

// @range(0, 1) Strength of the lens at its peak
const float strength = 0.8;

vec4 transition(vec2 uv) {
  // lens amount: grows, peaks in the middle, then relaxes, eased so that
  // the magnification of the center (1 / (1 - k)) changes at an even pace
  float h = smoothstep(0.0, 1.0, 1.0 - abs(2.0 * progress - 1.0));
  float k = 1.0 - pow(max(1.0 - strength, 0.01), h);
  // round lens: aspect-corrected coordinates, 1.0 at the corners
  vec2 aspect = vec2(ratio, 1.0);
  vec2 c = (uv - 0.5) * aspect;
  float r = length(c) / length(0.5 * aspect);
  // barrel mapping that keeps the corners in place: the center is magnified,
  // the edges squeezed, and every sample stays inside the image
  vec2 q = 0.5 + (uv - 0.5) * (1.0 - k + k * r * r);
  return mix(getFromColor(q), getToColor(q), smoothstep(0.38, 0.62, progress));
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
