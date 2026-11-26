#version 460 core
// gl-transitions (https://gl-transitions.com) — NoiseDissolve by towrabbit, MIT.
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

// Author: towrabbit
// License: MIT
// Description: The incoming image appears pixel by pixel in random noise
// Tags: dissolve, noise

float random (vec2 st) {
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}
vec4 transition (vec2 uv) {
  vec4 leftSide = getFromColor(uv);
  vec4 rightSide = getToColor(uv);
  float uvz = step(0.001 + 0.998 * random(uv), progress);
  return mix(leftSide,rightSide,uvz);
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
