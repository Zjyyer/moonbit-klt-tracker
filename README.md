# moonbit-klt-tracker

[简体中文](README.zh-CN.md)

`moonbit-klt-tracker` is a MoonBit-native, deterministic sparse feature-tracking library for ordered grayscale frame buffers. Version 1 provides checked grayscale frames, image pyramids and gradients, Shi–Tomasi feature detection, pyramidal Lucas–Kanade (KLT) tracking, quality diagnostics, track lifecycle management, deterministic JSON/CSV exports, and `detect`, `track`, and `inspect` command-line workflows.

## Scope

Version 1 deliberately does not include image or video codecs, camera capture, GPU acceleration, deep-learning models, dense optical flow, an interactive GUI, or general-purpose computer-vision primitives. Supply decoded grayscale bytes from your own application or an external adapter.

## Status

The project is being built incrementally. Public APIs and runnable examples will be documented as their packages land.

## License

Apache-2.0. See [LICENSE](LICENSE).
