///|
fn validate_correspondences(
  samples : Array[Correspondence],
) -> Result[Unit, MotionError] {
  for sample in samples {
    if !finite(sample.source.x) ||
      !finite(sample.source.y) ||
      !finite(sample.target.x) ||
      !finite(sample.target.y) {
      return Err(NonFiniteInput)
    }
  }
  Ok(())
}

///|
/// Estimates a translation by averaging measured displacement vectors.
pub fn fit_translation(
  samples : Array[Correspondence],
  config : FitConfig,
) -> Result[Translation, MotionError] {
  if samples.length() < config.minimum_inliers {
    return Err(InsufficientSamples)
  }
  match validate_correspondences(samples) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  for sample in samples {
    sum_x += sample.target.x - sample.source.x
    sum_y += sample.target.y - sample.source.y
  }
  let result : @math.Vec2 = {
    x: sum_x / samples.length().to_double(),
    y: sum_y / samples.length().to_double(),
  }
  if finite(result.x) && finite(result.y) {
    Ok(Translation::new(result))
  } else {
    Err(NonFiniteResult)
  }
}

///|
/// Estimates the six affine coefficients through normal equations.
pub fn fit_affine(
  samples : Array[Correspondence],
  config : FitConfig,
) -> Result[Affine, MotionError] {
  if samples.length() < 3 || samples.length() < config.minimum_inliers {
    return Err(InsufficientSamples)
  }
  match validate_correspondences(samples) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let matrix : Array[Array[Double]] = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  ]
  for sample in samples {
    accumulate_affine_equation(
      matrix,
      [sample.source.x, sample.source.y, 1.0],
      sample.target.x,
      0,
    )
    accumulate_affine_equation(
      matrix,
      [sample.source.x, sample.source.y, 1.0],
      sample.target.y,
      1,
    )
  }
  match solve_dense(matrix, 6) {
    Ok(values) =>
      Ok(
        Affine::new(
          values[0],
          values[1],
          values[2],
          values[3],
          values[4],
          values[5],
        ),
      )
    Err(error) => Err(error)
  }
}

///|
fn accumulate_affine_equation(
  matrix : Array[Array[Double]],
  row : Array[Double],
  output : Double,
  block : Int,
) -> Unit {
  let offset = block * 3
  for i in 0..<3 {
    for j in 0..<3 {
      matrix[offset + i][offset + j] += row[i] * row[j]
    }
    matrix[offset + i][6] += row[i] * output
  }
}

///|
fn solve_dense(
  matrix : Array[Array[Double]],
  size : Int,
) -> Result[Array[Double], MotionError] {
  for pivot in 0..<size {
    let mut best = pivot
    for candidate in (pivot + 1)..<size {
      if abs(matrix[candidate][pivot]) > abs(matrix[best][pivot]) {
        best = candidate
      }
    }
    if abs(matrix[best][pivot]) <= 0.000000000001 {
      return Err(SingularSystem)
    }
    if best != pivot {
      let row = matrix[pivot]
      matrix[pivot] = matrix[best]
      matrix[best] = row
    }
    let divisor = matrix[pivot][pivot]
    for column in pivot..<(size + 1) {
      matrix[pivot][column] /= divisor
    }
    for row_index in 0..<size {
      if row_index != pivot {
        let factor = matrix[row_index][pivot]
        for column in pivot..<(size + 1) {
          matrix[row_index][column] -= factor * matrix[pivot][column]
        }
      }
    }
  }
  let result : Array[Double] = []
  for index in 0..<size {
    if !finite(matrix[index][size]) {
      return Err(NonFiniteResult)
    }
    result.push(matrix[index][size])
  }
  Ok(result)
}

///|
/// Runs a deterministic translation consensus search over evenly spaced samples.
pub fn consensus_translation(
  samples : Array[Correspondence],
  config : FitConfig,
) -> Result[ConsensusTranslation, MotionError] {
  if samples.length() < config.minimum_inliers {
    return Err(InsufficientSamples)
  }
  match validate_correspondences(samples) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let mut best_count = -1
  let mut best_error = 1.0 / 0.0
  let mut best_model = Translation::new({ x: 0.0, y: 0.0 })
  let limit = if config.iterations < samples.length() {
    config.iterations
  } else {
    samples.length()
  }
  for index in 0..<limit {
    let sample = samples[index]
    let candidate = Translation::new({
      x: sample.target.x - sample.source.x,
      y: sample.target.y - sample.source.y,
    })
    let mut count = 0
    let mut error = 0.0
    for other in samples {
      let residual = candidate.residual(other.source, other.target)
      if residual <= config.threshold {
        count += 1
        error += residual
      }
    }
    if count > best_count || (count == best_count && error < best_error) {
      best_count = count
      best_error = error
      best_model = candidate
    }
  }
  if best_count < config.minimum_inliers {
    return Err(DegenerateGeometry)
  }
  let summary = residual_summary(
    samples,
    MotionModel::TranslationModel(best_model),
    config.threshold,
  )
  Ok({ model: best_model, inlier_count: best_count, residual: summary })
}

///|
/// Computes finite residual counters for a generic model.
pub fn residual_summary(
  samples : Array[Correspondence],
  model : MotionModel,
  threshold : Double,
) -> ResidualSummary {
  let mut count = 0
  let mut inliers = 0
  let mut rejected = 0
  let mut sum = 0.0
  let mut squared = 0.0
  let mut maximum = 0.0
  for sample in samples {
    count += 1
    match model.transform(sample.source) {
      Ok(target) => {
        let residual = distance(target, sample.target)
        if finite(residual) {
          sum += residual
          squared += residual * residual
          if residual > maximum {
            maximum = residual
          }
          if residual <= threshold {
            inliers += 1
          } else {
            rejected += 1
          }
        } else {
          rejected += 1
        }
      }
      Err(_) => rejected += 1
    }
  }
  let mean = if count == 0 { 0.0 } else { sum / count.to_double() }
  let rms = if count == 0 { 0.0 } else { (squared / count.to_double()).sqrt() }
  { count, inlier_count: inliers, rejected_count: rejected, mean, maximum, rms }
}
