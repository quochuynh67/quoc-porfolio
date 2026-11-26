#version 460 core
// gl-transitions (https://gl-transitions.com) — RectangleCover by martiniti, MIT.
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

// Author: martiniti
// License: MIT
// Description: A rectangle grows from the center to cover the outgoing image, then shrinks to reveal the incoming one
// Tags: box, shape, iris

// @color Color of the rectangle
const vec4 bgcolor = vec4(0.0, 0.0, 0.0, 1.0);

vec4 transition(vec2 p) {
  float s = pow(2.0 * abs(progress - 0.5), 3.0);
  
   vec2 sq = p.xy / vec2(1.0).xy;
   
    vec2 bl = step(vec2(abs(1. - 2.*progress)), sq + .25);
    float dist = bl.x * bl.y;

    vec2 tr = step(vec2(abs(1. - 2.*progress)), 1.25-sq);
    dist *= 1. * tr.x * tr.y;
  
  return mix(
    progress < 0.5 ? getFromColor(p) : getToColor(p),
    bgcolor,
    step(s, dist)
  );
  
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
