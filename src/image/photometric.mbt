///|
/// Finite photometric gain and bias mapping target = gain * source + bias.
pub(all) struct PhotometricModel {
  gain : Double
  bias : Double
  correlation : Double
  error : Double
} derive(Debug)

///|
pub(all) enum PhotometricError {
  EmptyPatch
  LengthMismatch
  NonFiniteValue
  ConstantSource
  NonFiniteResult
} derive(Debug, Eq)

///|
/// Estimates brightness gain and bias using centered least squares.
pub fn estimate_photometric(
  source : Array[Double],
  target : Array[Double],
) -> Result[PhotometricModel, PhotometricError] {
  if source.length() == 0 {
    return Err(EmptyPatch)
  }
  if source.length() != target.length() {
    return Err(LengthMismatch)
  }
  let mut source_mean = 0.0
  let mut target_mean = 0.0
  for index in 0..<source.length() {
    if !finite(source[index]) || !finite(target[index]) {
      return Err(NonFiniteValue)
    }
    source_mean += source[index]
    target_mean += target[index]
  }
  let count = source.length().to_double()
  source_mean /= count
  target_mean /= count
  let mut covariance = 0.0
  let mut source_variance = 0.0
  let mut target_variance = 0.0
  for index in 0..<source.length() {
    let source_delta = source[index] - source_mean
    let target_delta = target[index] - target_mean
    covariance += source_delta * target_delta
    source_variance += source_delta * source_delta
    target_variance += target_delta * target_delta
  }
  if source_variance <= 0.000000000001 {
    return Err(ConstantSource)
  }
  let gain = covariance / source_variance
  let bias = target_mean - gain * source_mean
  let correlation = if target_variance <= 0.000000000001 {
    0.0
  } else {
    covariance / (source_variance * target_variance).sqrt()
  }
  let mut squared_error = 0.0
  for index in 0..<source.length() {
    let difference = gain * source[index] + bias - target[index]
    squared_error += difference * difference
  }
  let error = (squared_error / count).sqrt()
  if finite(gain) && finite(bias) && finite(correlation) && finite(error) {
    Ok({ gain, bias, correlation, error })
  } else {
    Err(NonFiniteResult)
  }
}

///|
pub fn apply_photometric(
  model : PhotometricModel,
  value : Double,
) -> Result[Double, PhotometricError] {
  let result = model.gain * value + model.bias
  if finite(value) && finite(result) {
    Ok(result)
  } else {
    Err(NonFiniteResult)
  }
}

///|
/// Clips a finite sample to a byte-like range.
pub fn clip_intensity(
  value : Double,
  minimum : Double,
  maximum : Double,
) -> Double? {
  if !finite(value) || !finite(minimum) || !finite(maximum) || minimum > maximum {
    None
  } else {
    Some(value.max(minimum).min(maximum))
  }
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}
