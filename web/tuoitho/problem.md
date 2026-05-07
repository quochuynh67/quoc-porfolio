# EmulatorJS iOS Crash Optimization Guide

This document explains how to optimize EmulatorJS code to reduce or avoid crashes on iOS browsers. The issue affects not only Safari but also Chrome and other browsers on iPhone and iPad, because all iOS browsers use the same WebKit engine.

## Problem Summary

EmulatorJS works on desktop browsers, but crashes on iOS browsers across Safari, Chrome, Edge, and other browsers. This is expected because all iOS browsers are required to use WebKit, so if WebKit crashes, every browser on the device can crash in the same way.

## Likely Root Cause

The crash is likely caused by a combination of:
- WebKit engine instability on iOS.
- High memory usage from WebAssembly or WebGL.
- Threads or `SharedArrayBuffer` usage.
- Large startup assets.
- Heavy UI and debug features.
- Platform-level browser bugs such as WebKit bug [284752](https://bugs.webkit.org/show_bug.cgi?id=284752).

Because of that, the code should not assume that switching from Safari to Chrome on iOS will help.

## Important iOS Browser Behavior

On iOS, Chrome is not a separate rendering engine from Safari. It still uses WebKit under the hood, which means:
- Safari and Chrome share the same core browser limitations.
- A crash in one is often a crash in the other.
- WebKit-related bugs affect all browsers on iPhone and iPad.

## Optimization Goal

The goal is not to maximize performance on iOS. The goal is to make the emulator **stable first**, even if that means reducing features, lowering memory usage, and disabling advanced runtime options.

## iOS Detection

Add iOS detection early in the startup code:

```javascript
const isIOS =
  /iPad|iPhone|iPod/.test(navigator.userAgent) ||
  (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
```

This covers both iPhone/iPad and iPadOS devices that identify as Mac-like platforms.

## Thread Handling

Threads should be disabled on iOS.

```javascript
window.EJS_threads = !isIOS && window.EJS_threads === true;
```

Or, if you are using a manual flag:

```javascript
let enableThreads = false;

if (!isIOS && window.SharedArrayBuffer) {
  enableThreads = true;
}

window.EJS_threads = enableThreads;
```

Do not rely on `SharedArrayBuffer` alone, because iOS may still fail even when the browser exposes partial support.

## Recommended Runtime Configuration

Use a lighter runtime config for iOS:

```javascript
window.EJS_player = '#game';
window.EJS_gameUrl = window.EJS_gameUrl || '';
window.EJS_biosUrl = window.EJS_biosUrl || '';
window.EJS_pathtodata = '/data/';
window.EJS_language = 'vi-VN';
window.EJS_startOnLoaded = true;
window.EJS_backgroundColor = '#000';
window.EJS_volume = 0.8;
window.EJS_DEBUG_XX = false;
window.EJS_threads = !isIOS ? window.EJS_threads : false;
```

For iOS, keep the config minimal and avoid extra runtime features.

## Memory Reduction

To reduce crash risk, minimize memory usage in both build and runtime.

### What to reduce
- Initial WASM memory.
- Maximum memory cap.
- Cache size.
- Number of preloaded assets.
- Texture resolution.
- Audio buffer size.
- Debug logs and overlays.

### Suggested approach
- Load only the files required to start the game.
- Avoid loading multiple emulator instances.
- Avoid large ROM collections in a single session.
- Avoid keeping unnecessary objects in memory.
- Prefer browser caching only for small essential assets.

## Cache Configuration

If EmulatorJS caching is enabled, lower the cache size on iOS:

```javascript
window.EJS_cacheConfig = {
  enabled: true,
  cacheMaxSizeMB: isIOS ? 256 : 2048,
  cacheMaxAgeMins: 7200
};
```

This reduces memory pressure and avoids large storage overhead on mobile WebKit.

## UI Simplification

Hide features that are not essential on iOS:

```javascript
if (isIOS) {
  window.EJS_Buttons = {
    saveState: false,
    loadState: false,
    screenRecord: false,
    cacheManager: false,
    settings: true,
    fullscreen: true,
    volume: true
  };
}
```

Keeping the UI simple helps reduce DOM overhead and lowers the chance of instability.

## WebGL Optimization

iOS browsers are sensitive to heavy WebGL usage, so keep rendering simple.

### Recommendations
- Use lower-resolution textures.
- Avoid expensive shader effects.
- Avoid very large frame buffers.
- Prefer WebGL 1 if WebGL 2 is not required.
- Keep the canvas size reasonable.
- Avoid unnecessary post-processing.

If the emulator offers rendering options, choose the most conservative one for iOS.

## Emscripten Build Strategy

If you control the WASM build, apply conservative memory settings.

### Good direction
- Lower `INITIAL_MEMORY`.
- Keep `ALLOW_MEMORY_GROWTH=1` only if needed.
- Set a moderate `MAXIMUM_MEMORY`.
- Disable threads for iOS builds.
- Remove unused modules and assets.

### What to avoid
- Very large initial heap sizes.
- Threaded WASM on iOS.
- Aggressive preload bundles.
- Excessive runtime logging.

## Startup Flow

A safe startup sequence should be:

1. Detect the platform.
2. If iOS, switch to lightweight mode.
3. Disable threads.
4. Reduce cache usage.
5. Hide non-essential UI.
6. Load only required assets.
7. Start the emulator.
8. Avoid extra work during initial render.

This order is important because iOS crashes are often triggered during early memory spikes.

## Suggested Code Patch

Here is a clean version you can adapt:

```javascript
const isIOS =
  /iPad|iPhone|iPod/.test(navigator.userAgent) ||
  (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

let enableThreads = false;

if (!isIOS && window.SharedArrayBuffer) {
  enableThreads = true;
}

window.EJS_player = '#game';
window.EJS_gameUrl = window.EJS_gameUrl || '';
window.EJS_biosUrl = window.EJS_biosUrl || '';
window.EJS_pathtodata = '/data/';
window.EJS_language = 'vi-VN';
window.EJS_startOnLoaded = true;
window.EJS_backgroundColor = '#000';
window.EJS_volume = 0.8;
window.EJS_DEBUG_XX = false;
window.EJS_threads = enableThreads;
window.EJS_cacheConfig = {
  enabled: true,
  cacheMaxSizeMB: isIOS ? 256 : 2048,
  cacheMaxAgeMins: 7200
};

if (isIOS) {
  window.EJS_Buttons = {
    saveState: false,
    loadState: false,
    screenRecord: false,
    cacheManager: false,
    settings: true,
    fullscreen: true,
    volume: true
  };
}
```

## Important Notes

If the crash is caused by WebKit bug [284752](https://bugs.webkit.org/show_bug.cgi?id=284752), then your code fix may not completely eliminate the underlying browser bug. The best you can do is reduce the chance that the emulator triggers the crash by lowering memory pressure and disabling risky features.

## Practical Priority Order

1. Disable threads on iOS.
2. Lower cache size.
3. Reduce startup assets.
4. Simplify UI.
5. Lower WASM memory usage.
6. Reduce WebGL load.
7. Retest on real iOS devices.

## Final Recommendation

The best optimization for EmulatorJS on iOS is a dedicated fallback mode with no threads, low memory, simple UI, and minimal startup loading. That gives the highest chance of stability across all iOS browsers.