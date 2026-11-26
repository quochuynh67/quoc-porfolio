#version 460 core
// gl-transitions (https://gl-transitions.com) — Curtains by gre, MIT.
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
// Description: The outgoing image parts in the middle like stage curtains, gathering into shaded folds as it is pulled to the sides
// Tags: split, horizontal, fold, 3d

// @range(1, 16, 1) Number of folds in each curtain (fewer in a portrait image)
const float folds = 7.0;
// @range(0, 1) Depth of the shading on the folds
const float shading = 0.7;
// @range(0, 0.4) Width of each curtain once gathered, relative to the image width
const float bunch = 0.12;
// @range(0, 1) How much the bottom of the curtains lags behind the top
const float sway = 0.4;

const float PI = 3.141592653589793;

vec4 transition (vec2 uv) {
  float lag = sway * (1.0 - uv.y);
  float p = progress * (1.0 - lag * (1.0 - progress));
  float open = mix(p, p * p * (3.0 - 2.0 * p), 0.75);
  // each curtain hangs from its outer edge, gathers to the bunch width, then leaves the frame
  float edge = -bunch * open * open;
  float w = mix(0.5, bunch, open);
  float x = min(uv.x, 1.0 - uv.x) - edge;
  if (x >= w) {
    vec4 to = getToColor(uv);
    float shadow = 0.4 * exp((w - x) * 25.0) * clamp((edge + w) * 20.0, 0.0, 1.0);
    return vec4(to.rgb * (1.0 - shadow * open), to.a);
  }
  float t = x / w;
  // pleats: the fabric bunches up where cos(a) > 0 and is stretched elsewhere
  float n = max(1.0, floor(folds * min(ratio, 1.0) + 0.5)); // folds keep their size in portrait
  float a = 2.0 * PI * n * t;
  float f = 1.0 - (1.0 - open) * (1.0 - open) * (1.0 - open);
  float gather = 0.92 * f;
  float s = 0.5 * (t + gather * sin(a) / (2.0 * PI * n));
  vec4 c = getFromColor(vec2(uv.x < 0.5 ? s : 1.0 - s, uv.y));
  float slope = 3.0 * gather * cos(a) * (uv.x < 0.5 ? 1.0 : -1.0);
  float diffuse = (1.0 + 0.5 * slope) / sqrt(1.25 * (1.0 + slope * slope));
  float crease = 0.5 + 0.5 * sin(a); // the back of each pleat is in the dark
  float light = mix(1.0, diffuse * (1.0 - 0.6 * crease * crease), shading * f);
  return vec4(c.rgb * light, c.a);
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
