///|
/// A scored point that can initialize a feature track.
pub(all) struct SeedPoint {
  position : @math.Vec2
  score : Double
} derive(Debug)

///|
/// Parameters for deterministic Shi-Tomasi feature detection.
pub(all) struct FeatureConfig {
  window_size : Int
  minimum_score : Double
  max_features : Int
  suppression_radius : Double
} derive(Debug)

///|
/// An invalid feature configuration or caller-provided seed.
pub(all) enum FeatureError {
  InvalidWindowSize
  InvalidMinimumScore
  InvalidMaximumFeatures
  InvalidSuppressionRadius
  FrameTooSmall
  SeedOutsideFrame(index~ : Int)
} derive(Debug, Eq)

///|
/// Validates that all supplied seeds are finite points within the frame domain.
pub fn validate_seeds(
  frame : @image.GrayFrame,
  seeds : Array[SeedPoint],
) -> Result[Array[SeedPoint], FeatureError] {
  let max_x = (frame.width - 1).to_double()
  let max_y = (frame.height - 1).to_double()
  for index, seed in seeds {
    let point = seed.position
    if point.x.is_nan() ||
      point.y.is_nan() ||
      point.x < 0.0 ||
      point.y < 0.0 ||
      point.x > max_x ||
      point.y > max_y {
      return Err(SeedOutsideFrame(index~))
    }
  }
  Ok(seeds)
}
