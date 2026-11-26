#version 460 core
// gl-transitions (https://gl-transitions.com) — WedgeWipe by gre, MIT.
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
// Description: Two hands sweep away from each other around the center, opening a widening wedge that reveals the incoming image
// Tags: wipe, radial, clock, wedge

#define PI 3.141592653589793

// @range(-180, 180) Direction the wedge opens from, in degrees clockwise from 12 o'clock
const float angle = 0.0;
// @range(0, 0.2) Softness of the hands' edges
const float smoothness = 0.01;
// @param Point the hands turn around
const vec2 center = vec2(0.5);

vec4 transition (vec2 uv) {
  // Measured in square pixels, so the angles are not stretched
  vec2 q = (uv - center) * vec2(ratio, 1.0);
  float a = radians(angle);
  // Local frame: y along the starting direction, x across it (the wedge is symmetric)
  vec2 p = vec2(abs(q.x * cos(a) - q.y * sin(a)), q.x * sin(a) + q.y * cos(a));
  float spread = PI * progress;
  // (float PI rounds above pi, so sin(spread) would turn slightly negative at the end)
  vec2 hand = vec2(max(sin(spread), 0.0), cos(spread));
  // Signed distance to the wedge: the nearest hand, negative inside
  float l = length(p);
  float d = length(p - hand * clamp(dot(p, hand), 0.0, l)) * sign(hand.y * p.x - hand.x * p.y);
  // The soft edge keeps an even width and slides from outside to inside the hands,
  // so nothing is revealed at the start and everything is at the end
  float s = max(smoothness, 0.001);
  float m = 1.0 - smoothstep(0.0, s, d + s * (1.0 - progress));
  return mix(getFromColor(uv), getToColor(uv), m);
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
