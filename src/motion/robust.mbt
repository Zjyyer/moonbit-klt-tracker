///|
/// Robust loss families used to down-weight motion outliers.
pub(all) enum RobustLoss {
  Huber
  Tukey
  Cauchy
  L1
} derive(Debug, Eq)

///|
pub(all) struct RobustConfig {
  loss : RobustLoss
  scale : Double
  maximum_iterations : Int
  tolerance : Double
} derive(Debug)

///|
pub fn RobustConfig::new(
  loss : RobustLoss,
  scale : Double,
  maximum_iterations : Int,
  tolerance : Double,
) -> Result[RobustConfig, MotionError] {
  if !finite(scale) ||
    scale <= 0.0 ||
    maximum_iterations < 1 ||
    !finite(tolerance) ||
    tolerance <= 0.0 {
    Err(InvalidConfiguration)
  } else {
    Ok({ loss, scale, maximum_iterations, tolerance })
  }
}

///|
pub fn robust_weight(config : RobustConfig, residual : Double) -> Double {
  if !finite(residual) {
    return 0.0
  }
  let normalized = abs(residual) / config.scale
  match config.loss {
    Huber => if normalized <= 1.0 { 1.0 } else { 1.0 / normalized }
    Tukey =>
      if normalized >= 1.0 {
        0.0
      } else {
        let remaining = 1.0 - normalized * normalized
        remaining * remaining
      }
    Cauchy => 1.0 / (1.0 + normalized * normalized)
    L1 => if normalized == 0.0 { 1.0 } else { 1.0 / normalized }
  }
}

///|
pub fn robust_loss(config : RobustConfig, residual : Double) -> Double {
  if !finite(residual) {
    return 1.0 / 0.0
  }
  let normalized = abs(residual) / config.scale
  match config.loss {
    Huber =>
      if normalized <= 1.0 {
        0.5 * normalized * normalized
      } else {
        normalized - 0.5
      }
    Tukey =>
      if normalized >= 1.0 {
        1.0 / 6.0
      } else {
        let remaining = 1.0 - normalized * normalized
        (1.0 - remaining * remaining * remaining) / 6.0
      }
    Cauchy => 0.5 * normalized * normalized / (1.0 + normalized * normalized)
    L1 => normalized
  }
}

///|
/// Returns a robust median without mutating caller storage.
pub fn median(values : Array[Double]) -> Result[Double, MotionError] {
  if values.length() == 0 {
    return Err(InsufficientSamples)
  }
  let ordered = values.copy()
  for value in ordered {
    if !finite(value) {
      return Err(NonFiniteInput)
    }
  }
  ordered.sort_by(fn(left, right) { left.compare(right) })
  let middle = ordered.length() / 2
  if ordered.length() % 2 == 1 {
    Ok(ordered[middle])
  } else {
    Ok((ordered[middle - 1] + ordered[middle]) / 2.0)
  }
}

///|
/// Returns median absolute deviation, scaled to a Gaussian-equivalent sigma.
pub fn median_absolute_deviation(
  values : Array[Double],
) -> Result[Double, MotionError] {
  let center = match median(values) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let deviations : Array[Double] = []
  for value in values {
    deviations.push(abs(value - center))
  }
  match median(deviations) {
    Ok(value) => Ok(value * 1.4826)
    Err(error) => Err(error)
  }
}

///|
/// Iteratively computes a robust location estimate.
pub fn robust_location(
  values : Array[Double],
  config : RobustConfig,
) -> Result[Double, MotionError] {
  if values.length() == 0 {
    return Err(InsufficientSamples)
  }
  let mut location = match median(values) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  for _ in 0..<config.maximum_iterations {
    let mut weighted_sum = 0.0
    let mut total_weight = 0.0
    for value in values {
      let weight = robust_weight(config, value - location)
      weighted_sum += weight * value
      total_weight += weight
    }
    if total_weight <= 0.000000000001 {
      return Err(DegenerateGeometry)
    }
    let next = weighted_sum / total_weight
    if abs(next - location) <= config.tolerance {
      return Ok(next)
    }
    location = next
  }
  Ok(location)
}

///|
pub(all) struct RobustSummary {
  count : Int
  inlier_count : Int
  outlier_count : Int
  weighted_mean : Double
  median : Double
  mad : Double
  total_loss : Double
} derive(Debug)

///|
pub fn summarize_robust(
  values : Array[Double],
  config : RobustConfig,
) -> Result[RobustSummary, MotionError] {
  let center = match median(values) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let deviation = match median_absolute_deviation(values) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut weighted_sum = 0.0
  let mut total_weight = 0.0
  let mut inliers = 0
  let mut loss = 0.0
  for value in values {
    let weight = robust_weight(config, value - center)
    if weight > 0.0 {
      inliers += 1
    }
    weighted_sum += weight * value
    total_weight += weight
    loss += robust_loss(config, value - center)
  }
  if total_weight == 0.0 {
    Err(DegenerateGeometry)
  } else {
    Ok({
      count: values.length(),
      inlier_count: inliers,
      outlier_count: values.length() - inliers,
      weighted_mean: weighted_sum / total_weight,
      median: center,
      mad: deviation,
      total_loss: loss,
    })
  }
}
