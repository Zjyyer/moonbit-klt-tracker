///|
/// Descriptive statistics for a sampled patch.
pub(all) struct PatchStatistics {
  count : Int
  minimum : Double
  maximum : Double
  mean : Double
  variance : Double
  standard_deviation : Double
  dynamic_range : Double
} derive(Debug)

///|
pub fn patch_statistics(
  values : Array[Double],
) -> Result[PatchStatistics, PhotometricError] {
  if values.length() == 0 {
    return Err(EmptyPatch)
  }
  let mut minimum = values[0]
  let mut maximum = values[0]
  let mut mean = 0.0
  for value in values {
    if !finite(value) {
      return Err(NonFiniteValue)
    }
    if value < minimum {
      minimum = value
    }
    if value > maximum {
      maximum = value
    }
    mean += value
  }
  mean /= values.length().to_double()
  let mut variance = 0.0
  for value in values {
    let delta = value - mean
    variance += delta * delta
  }
  variance /= values.length().to_double()
  Ok({
    count: values.length(),
    minimum,
    maximum,
    mean,
    variance,
    standard_deviation: variance.sqrt(),
    dynamic_range: maximum - minimum,
  })
}

///|
/// Z-score normalizes a finite patch without changing its length.
pub fn normalize_patch(
  values : Array[Double],
) -> Result[Array[Double], PhotometricError] {
  match patch_statistics(values) {
    Err(error) => Err(error)
    Ok(statistics) => {
      if statistics.standard_deviation <= 0.000000000001 {
        return Err(ConstantSource)
      }
      let result : Array[Double] = []
      for value in values {
        result.push((value - statistics.mean) / statistics.standard_deviation)
      }
      Ok(result)
    }
  }
}

///|
/// Normalizes a patch to a requested closed interval.
pub fn rescale_patch(
  values : Array[Double],
  minimum : Double,
  maximum : Double,
) -> Result[Array[Double], PhotometricError] {
  if minimum > maximum || !finite(minimum) || !finite(maximum) {
    return Err(NonFiniteResult)
  }
  match patch_statistics(values) {
    Err(error) => Err(error)
    Ok(statistics) => {
      if statistics.dynamic_range <= 0.000000000001 {
        return Err(ConstantSource)
      }
      let result : Array[Double] = []
      for value in values {
        let ratio = (value - statistics.minimum) / statistics.dynamic_range
        result.push(minimum + ratio * (maximum - minimum))
      }
      Ok(result)
    }
  }
}
