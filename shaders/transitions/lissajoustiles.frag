#version 460 core
// gl-transitions (https://gl-transitions.com) — LissajousTiles by Boundless <info@boundless-beta.com>, MIT.
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

// Author: Boundless <info@boundless-beta.com>
// License: MIT
// Description: The image breaks into a grid of tiles that swirl along Lissajous curves, in a Scanimate style, and flip one by one to the incoming image before settling back
// Tags: tiles, grid, motion, retro

// @param Speed of the tiles along their curves
const float speed = 0.5;;
// @param Number of loops of the curve, horizontally and vertically
const vec2 freq = vec2(2.,3.);;
// @param Extra vertical speed, which bends the curve
const float offset = 2.;;
// @range(0, 2) Size of the curve, relative to the image
const float zoom = 0.8;;
// @range(0, 10) Spread of the tile-by-tile switch to the incoming image
const float fade = 3.;;

const vec2 grid = vec2(10.,10.);
const float TAU = 6.283185307;

vec4 transition (vec2 uv) {
  // The tiles leave and come back with zero speed, so the image does not break apart in the first frame
  float p = 1.-pow(1.-smoothstep(0.,1.,1.-abs(1.-2.*progress)),3.);
  // Find the last tile that covers this pixel (looping backwards, the first hit), then sample the images once
  for (float jBig = grid.y-1.; jBig >= 0.; jBig--) {
    for (float iBig = grid.x-1.; iBig >= 0.; iBig--) {
      float i = iBig/grid.x;
      float j = jBig/grid.y;
      float k = i/grid.y+j; // order of the tile along the curve
      vec2 uv0 = uv + vec2(i,j) - 0.5 + 0.5/grid + vec2(cos(k*TAU*freq.x+progress*6.*speed),sin(k*TAU*freq.y+progress*6.*(1.+offset)*speed))*zoom/2.;
      uv0 = mix(uv, uv0, p);
      if (uv0.x >= i && uv0.x < i+1./grid.x && uv0.y >= j && uv0.y < j+1./grid.y) {
        float tileMix = clamp(progress*((1.+fade)*2.*progress)-fade+k*fade, 0., 1.);
        return mix(getFromColor(uv0), getToColor(uv0), tileMix);
      }
    }
  }
  return vec4(0.); // between the tiles: transparent
}


void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
