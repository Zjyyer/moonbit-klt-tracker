///|
const FORWARD_BACKWARD_THRESHOLD : Double = 1.0

///|
fn with_forward_backward_error(
  forward : @klt.KltObservation,
  error : Double,
  status : @klt.KltStatus,
) -> @klt.KltObservation {
  {
    source: forward.source,
    target: forward.target,
    displacement: forward.displacement,
    residual: forward.residual,
    minimum_eigenvalue: forward.minimum_eigenvalue,
    iterations: forward.iterations,
    pyramid_level: forward.pyramid_level,
    forward_backward_error: error,
    status,
  }
}

///|
/// Keeps forward tracks whose reverse track returns within one pixel of `seed`.
///
/// Reverse tracking begins at the forward endpoint and runs from `next` into
/// `previous`.  The returned observation preserves the forward diagnostics and
/// records the finite round-trip distance.
pub fn validate_forward_backward(
  previous : @image.Pyramid,
  next : @image.Pyramid,
  seed : @features.SeedPoint,
  forward : @klt.KltObservation,
  config : @klt.KltConfig,
) -> @klt.KltObservation {
  if forward.status != @klt.Tracked {
    return with_forward_backward_error(forward, 0.0, forward.status)
  }
  let backward_seed : @features.SeedPoint = {
    position: forward.target,
    score: seed.score,
  }
  let backward = @klt.track_pyramidal(next, previous, backward_seed, config)
  if backward.status != @klt.Tracked {
    return with_forward_backward_error(forward, 0.0, @klt.Rejected)
  }
  let dx = backward.target.x - seed.position.x
  let dy = backward.target.y - seed.position.y
  let error = (dx * dx + dy * dy).sqrt()
  if error.is_nan() || error.is_inf() {
    return with_forward_backward_error(forward, 0.0, @klt.Rejected)
  }
  let status = if error > FORWARD_BACKWARD_THRESHOLD {
    @klt.Rejected
  } else {
    @klt.Tracked
  }
  with_forward_backward_error(forward, error, status)
}
