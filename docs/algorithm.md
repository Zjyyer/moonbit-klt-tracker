# Algorithm and limitations

## Pipeline

1. Validate grayscale dimensions and pixels, then build the requested image-pyramid levels.
2. Detect Shi-Tomasi seed points with a configurable window, score threshold, maximum count, and suppression radius, or validate caller-supplied seeds.
3. At the coarsest pyramid level, start displacement at zero. At each finer level, double the prior displacement and call the single-level solver.
4. The single-level solver uses fixed source-image gradients, forms the 2x2 gradient matrix over an odd square window, rejects insufficient texture using its smaller eigenvalue, and iteratively updates a subpixel displacement using bilinear sampling.
5. For a tracked forward result, reverse-track from its target and reject it when the round trip exceeds one pixel.
6. Update active/lost lifecycle state, optionally redetect features on the configured interval, and serialize trajectories deterministically.

The implementation records source, target, displacement, RMS residual, smaller gradient-matrix eigenvalue, iteration count, pyramid level, forward-backward error, and an outcome of `Tracked`, `Rejected`, or `OutOfBounds` in `KltObservation`.

## Assumptions and non-goals

The local solver estimates translation, not affine, similarity, or projective motion. It assumes brightness constancy between source and target windows and uses gradients from the source frame; lighting variation, blur, repeated texture, large inter-frame displacement beyond the pyramid's capture range, and occlusion can therefore produce inaccurate motion or rejection. A successful result is a numerical observation, not a semantic guarantee that the same physical object remains visible.

This project intentionally omits dense optical flow, camera models, calibration, rolling-shutter compensation, codecs, capture, GPU/SIMD acceleration, deep-learning inference, and GUI interaction. It operates on caller-provided grayscale bytes and does not decode image or video formats.

The checked tests exercise synthetic translation, zero motion, rejection, bounds, forward-backward inconsistency, lifecycle handling, deterministic exports, and CLI fixtures. They are regression evidence for those cases, not proof of accuracy on arbitrary imagery.
