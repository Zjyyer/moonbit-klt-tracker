///|
fn scaled_seed(seed : @features.SeedPoint, scale : Double) -> @features.SeedPoint {
  { position: seed.position.scale(scale), score: seed.score }
}

///|
fn observation_at_level(observation : KltObservation, level : Int) -> KltObservation {
  {
    source: observation.source,
    target: observation.target,
    displacement: observation.displacement,
    residual: observation.residual,
    minimum_eigenvalue: observation.minimum_eigenvalue,
    iterations: observation.iterations,
    pyramid_level: level,
    forward_backward_error: observation.forward_backward_error,
    status: observation.status,
  }
}

///|
fn pyramidal_neutral_rejection() -> KltObservation {
  {
    source: @math.Vec2::{ x: 0.0, y: 0.0 },
    target: @math.Vec2::{ x: 0.0, y: 0.0 },
    displacement: @math.Vec2::{ x: 0.0, y: 0.0 },
    residual: 0.0,
    minimum_eigenvalue: 0.0,
    iterations: 0,
    pyramid_level: 0,
    forward_backward_error: 0.0,
    status: Rejected,
  }
}

///|
/// Tracks `seed` from the coarsest common pyramid layer to full resolution.
///
/// The displacement starts at zero at the coarsest layer and is doubled before
/// each successive finer-layer solve.  Any non-tracked layer result is returned
/// with its level retained for deterministic diagnostics.
pub fn track_pyramidal(
  previous : @image.Pyramid,
  next : @image.Pyramid,
  seed : @features.SeedPoint,
  config : KltConfig,
) -> KltObservation {
  let level_count = previous.level_count()
  if level_count == 0 || level_count != next.level_count() {
    return pyramidal_neutral_rejection()
  }
  let mut scale = 1.0
  for _ in 0..<(level_count - 1) {
    scale = scale * 0.5
  }
  let mut displacement : @math.Vec2 = { x: 0.0, y: 0.0 }
  let mut level = level_count - 1
  let mut first_level = true
  while level >= 0 {
    if !first_level {
      displacement = displacement.scale(2.0)
      scale = scale * 2.0
    }
    let source = previous.level(level)
    let target = next.level(level)
    let observation = track_single_level(
      source,
      target,
      @image.GradientFrame::from_frame(source),
      scaled_seed(seed, scale),
      displacement,
      config,
    )
    let result = observation_at_level(observation, level)
    if result.status != Tracked {
      return result
    }
    if level == 0 {
      return result
    }
    displacement = result.displacement
    first_level = false
    level = level - 1
  }
  pyramidal_neutral_rejection()
}
