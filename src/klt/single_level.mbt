///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn config_is_valid(config : KltConfig) -> Bool {
  config.window_size > 0 &&
  config.window_size % 2 == 1 &&
  config.max_iterations > 0 &&
  is_finite(config.update_epsilon) &&
  config.update_epsilon > 0.0 &&
  is_finite(config.minimum_eigenvalue) &&
  config.minimum_eigenvalue >= 0.0
}

///|
fn window_fits(
  width : Int,
  height : Int,
  center : @math.Vec2,
  radius : Int,
) -> Bool {
  is_finite(center.x) &&
  is_finite(center.y) &&
  center.x - radius.to_double() >= 0.0 &&
  center.y - radius.to_double() >= 0.0 &&
  center.x + radius.to_double() <= (width - 1).to_double() &&
  center.y + radius.to_double() <= (height - 1).to_double()
}

///|
fn observation(
  source : @math.Vec2,
  displacement : @math.Vec2,
  residual : Double,
  minimum_eigenvalue : Double,
  iterations : Int,
  status : KltStatus,
) -> KltObservation {
  {
    source,
    target: source.add(displacement),
    displacement,
    residual,
    minimum_eigenvalue,
    iterations,
    pyramid_level: 0,
    forward_backward_error: 0.0,
    status,
  }
}

///|
/// Tracks `seed` from `previous` into `next` using fixed source gradients.
///
/// This deterministic inverse-compositional-style iteration rejects windows
/// whose smaller gradient-matrix eigenvalue is below the configured threshold,
/// returns `OutOfBounds` if either complete window cannot be sampled, and
/// otherwise returns `Tracked` after convergence or the iteration cap.
pub fn track_single_level(
  previous : @image.GrayFrame,
  next : @image.GrayFrame,
  gradient : @image.GradientFrame,
  seed : @features.SeedPoint,
  initial : @math.Vec2,
  config : KltConfig,
) -> KltObservation {
  let source = seed.position
  if !config_is_valid(config) || !is_finite(initial.x) || !is_finite(initial.y) {
    return observation(source, initial, 0.0, 0.0, 0, Rejected)
  }
  let radius = config.window_size / 2
  if !window_fits(previous.width, previous.height, source, radius) ||
    !window_fits(gradient.width, gradient.height, source, radius) {
    return observation(source, initial, 0.0, 0.0, 0, OutOfBounds)
  }

  let mut a = 0.0
  let mut b = 0.0
  let mut c = 0.0
  let mut gradient_available = true
  for offset_y in -radius..<=radius {
    for offset_x in -radius..<=radius {
      let point : @math.Vec2 = {
        x: source.x + offset_x.to_double(),
        y: source.y + offset_y.to_double(),
      }
      match gradient.at(point) {
        Some(value) => {
          a = a + value.x * value.x
          b = b + value.x * value.y
          c = c + value.y * value.y
        }
        None => gradient_available = false
      }
    }
  }
  if !gradient_available || !is_finite(a) || !is_finite(b) || !is_finite(c) {
    return observation(source, initial, 0.0, 0.0, 0, OutOfBounds)
  }
  let discriminant = ((a - c) * (a - c) + 4.0 * b * b).sqrt()
  let minimum_eigenvalue = (a + c - discriminant) / 2.0
  if !is_finite(minimum_eigenvalue) ||
    minimum_eigenvalue < config.minimum_eigenvalue {
    return observation(source, initial, 0.0, minimum_eigenvalue, 0, Rejected)
  }

  let mut displacement = initial
  let mut residual = 0.0
  let mut iterations = 0
  let mut status = Tracked
  let mut active = true
  for _ in 0..<config.max_iterations {
    if active {
      let target = source.add(displacement)
      if !window_fits(next.width, next.height, target, radius) {
        status = OutOfBounds
        active = false
      } else {
        let mut rhs_x = 0.0
        let mut rhs_y = 0.0
        let mut squared_residual = 0.0
        let mut sample_count = 0
        let mut samples_available = true
        for offset_y in -radius..<=radius {
          for offset_x in -radius..<=radius {
            let source_point : @math.Vec2 = {
              x: source.x + offset_x.to_double(),
              y: source.y + offset_y.to_double(),
            }
            let target_point = source_point.add(displacement)
            match
              (
                previous.sample_bilinear(source_point),
                next.sample_bilinear(target_point),
                gradient.at(source_point),
              ) {
              (Some(previous_value), Some(next_value), Some(derivative)) => {
                let temporal = next_value - previous_value
                rhs_x = rhs_x + derivative.x * temporal
                rhs_y = rhs_y + derivative.y * temporal
                squared_residual = squared_residual + temporal * temporal
                sample_count = sample_count + 1
              }
              _ => samples_available = false
            }
          }
        }
        if !samples_available || sample_count == 0 {
          status = OutOfBounds
          active = false
        } else {
          residual = (squared_residual / sample_count.to_double()).sqrt()
          match @math.solve_symmetric_2x2(a, b, c, { x: rhs_x, y: rhs_y }) {
            Ok(update) => {
              let update_norm = (update.x * update.x + update.y * update.y).sqrt()
              if !is_finite(update_norm) || !is_finite(residual) {
                status = Rejected
                active = false
              } else {
                displacement = displacement.add(update.scale(-1.0))
                iterations = iterations + 1
                if update_norm <= config.update_epsilon {
                  active = false
                }
              }
            }
            Err(_) => {
              status = Rejected
              active = false
            }
          }
        }
      }
    }
  }
  observation(
    source, displacement, residual, minimum_eigenvalue, iterations, status,
  )
}
