#version 460 core
// Original flag-curtain transition for Quoc67K1 Studio (Thailand).
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

const float PI = 3.14159265;
float sdStar5(vec2 p, float r, float rf) {
  const vec2 k1 = vec2(0.809016994375, -0.587785252292);
  const vec2 k2 = vec2(-0.809016994375, -0.587785252292);
  p.x = abs(p.x);
  p -= 2.0 * max(dot(k1, p), 0.0) * k1;
  p -= 2.0 * max(dot(k2, p), 0.0) * k2;
  p.x = abs(p.x);
  p.y -= r;
  vec2 ba = rf * vec2(0.587785252292, 0.809016994375) - vec2(0.0, 1.0);
  float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
  return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}
vec2 rot(vec2 p, float a) {
  float c = cos(a), s = sin(a);
  return vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
}
float aa(float d) { return 1.0 - smoothstep(-0.004, 0.004, d); }

// q: position inside the flag in height units (origin bottom-left),
// n: the same normalised to 0..1 across width and height.
vec3 flagColor(vec2 q, vec2 n) {
  float t = 1.0 - clamp(n.y, 0.0, 1.0);
  if (t < 0.166667) return vec3(0.647, 0.098, 0.196);
  if (t < 0.333333) return vec3(1.0);
  if (t < 0.666667) return vec3(0.176, 0.169, 0.396);
  if (t < 0.833333) return vec3(1.0);
  return vec3(0.647, 0.098, 0.196);
}

vec4 transition(vec2 uv) {
  // A 3:2 flag card slides across the frame; everything behind it flips from
  // the outgoing to the incoming picture at the card's centre line.
  float hf = clamp(ratio / 1.5, 0.5, 1.0);      // card height (share of frame)
  float fw = 1.5 * hf / ratio;                  // card width (share of frame)
  float left = -fw + progress * (1.0 + fw);
  float f = (uv.x - left) / fw;
  float v = (uv.y - (0.5 - hf * 0.5)) / hf;
  vec4 under = uv.x < left + fw * 0.5 ? getToColor(uv) : getFromColor(uv);
  if (f < 0.0 || f > 1.0 || v < 0.0 || v > 1.0) return under;
  float phase = f * 6.0 - progress * 22.0;
  float vy = v + sin(phase) * 0.014 * (0.3 + f);
  vec2 q = vec2(f * 1.5, vy);
  vec2 n = vec2(f, vy);
  vec3 col = flagColor(q, n) * (1.0 + 0.16 * cos(phase));
  float edge = smoothstep(0.0, 0.015, min(min(f, 1.0 - f), min(v, 1.0 - v)));
  return mix(under, vec4(col, 1.0), edge);
}

void main() {
  vec2 frag = FlutterFragCoord().xy / uSize;
  progress = uProgress;
  ratio = uSize.x / uSize.y;
  fragColor = transition(vec2(frag.x, 1.0 - frag.y));
}
