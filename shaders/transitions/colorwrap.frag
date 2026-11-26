#version 460 core
// gl-transitions (https://gl-transitions.com) — ColorWrap by Yoni Maltsman @friendlyspinach, MIT.
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

// Author: Yoni Maltsman @friendlyspinach
// License: MIT
// Description: Each color channel of the outgoing image is shifted and wraps around into psychedelic bands, while crossfading to the incoming image
// Tags: color, glitch, psychedelic, fade

// @range(-2, 2) Shift of the red channel over the transition
const float r_strength = 1.0;
// @range(-2, 2) Shift of the green channel over the transition
const float g_strength = 1.0;
// @range(-2, 2) Shift of the blue channel over the transition
const float b_strength = 1.0;

vec4 transition (vec2 uv) {
  vec4 from = getFromColor(uv);
  vec4 to = getToColor(uv);
  vec3 c = from.rgb + vec3(r_strength, g_strength, b_strength)*progress;
  // The wrap flips bright (or, with negative strengths, dark) channels at once: fade it in over the first frames
  from.rgb = mix(from.rgb, mod(c, 1.0), smoothstep(0.0, 0.1, progress));
  return mix(from, to, progress);
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
