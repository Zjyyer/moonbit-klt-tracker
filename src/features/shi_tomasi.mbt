///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && (value == 0.0 || value / 2.0 != value)
}

///|
fn valid_config(config : FeatureConfig) -> FeatureError? {
  if config.window_size <= 0 || config.window_size % 2 == 0 {
    Some(InvalidWindowSize)
  } else if !is_finite(config.minimum_score) || config.minimum_score < 0.0 {
    Some(InvalidMinimumScore)
  } else if config.max_features < 0 {
    Some(InvalidMaximumFeatures)
  } else if !is_finite(config.suppression_radius) ||
    config.suppression_radius < 0.0 {
    Some(InvalidSuppressionRadius)
  } else {
    None
  }
}

///|
fn precedes(left : SeedPoint, right : SeedPoint) -> Bool {
  left.score > right.score ||
  (
    left.score == right.score &&
    (
      left.position.y < right.position.y ||
      (
        left.position.y == right.position.y &&
        left.position.x < right.position.x
      )
    )
  )
}

///|
fn sort_seeds(seeds : Array[SeedPoint]) -> Unit {
  for index in 1..<seeds.length() {
    let current = seeds[index]
    for insert_at = index; insert_at > 0 &&
       precedes(current, seeds[insert_at - 1]); {
      seeds[insert_at] = seeds[insert_at - 1]
      continue insert_at - 1
    } nobreak {
      seeds[insert_at] = current
    }
  }
}

///|
fn suppressed_by(
  seed : SeedPoint,
  selected : Array[SeedPoint],
  radius_squared : Double,
) -> Bool {
  for other in selected {
    let dx = seed.position.x - other.position.x
    let dy = seed.position.y - other.position.y
    if dx * dx + dy * dy <= radius_squared {
      return true
    }
  }
  false
}

///|
/// Detects deterministic Shi-Tomasi corner seeds and applies radius suppression.
pub fn detect_shi_tomasi(
  frame : @image.GrayFrame,
  config : FeatureConfig,
) -> Result[Array[SeedPoint], FeatureError] {
  match valid_config(config) {
    Some(error) => Err(error)
    None => {
      let radius = config.window_size / 2
      if frame.width <= radius * 2 || frame.height <= radius * 2 {
        return Err(FrameTooSmall)
      }
      let gradients = @image.GradientFrame::from_frame(frame)
      let candidates = []
      for y in radius..<(frame.height - radius) {
        for x in radius..<(frame.width - radius) {
          let mut xx = 0.0
          let mut xy = 0.0
          let mut yy = 0.0
          for offset_y in -radius..<=radius {
            for offset_x in -radius..<=radius {
              let point : @math.Vec2 = {
                x: (x + offset_x).to_double(),
                y: (y + offset_y).to_double(),
              }
              match gradients.at(point) {
                Some(gradient) => {
                  xx = xx + gradient.x * gradient.x
                  xy = xy + gradient.x * gradient.y
                  yy = yy + gradient.y * gradient.y
                }
                None => panic()
              }
            }
          }
          let trace = xx + yy
          let determinant = xx * yy - xy * xy
          let discriminant = (trace * trace - 4.0 * determinant).max(0.0)
          let score = (trace - discriminant.sqrt()) / 2.0
          if score >= config.minimum_score {
            candidates.push({
              position: { x: x.to_double(), y: y.to_double() },
              score,
            })
          }
        }
      }
      sort_seeds(candidates)
      let selected = []
      let radius_squared = config.suppression_radius * config.suppression_radius
      for candidate in candidates {
        if selected.length() >= config.max_features {
          break
        }
        if !suppressed_by(candidate, selected, radius_squared) {
          selected.push(candidate)
        }
      }
      Ok(selected)
    }
  }
}
