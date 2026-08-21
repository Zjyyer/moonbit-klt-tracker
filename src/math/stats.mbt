///|
/// Stable scalar statistics shared by image and trajectory reports.
pub(all) struct ScalarStats {
  count : Int
  minimum : Double
  maximum : Double
  mean : Double
  variance : Double
  sum : Double
  sum_absolute : Double
} derive(Debug)

///|
pub(all) enum StatsError {
  Empty
  NonFinite
  InvalidQuantile
} derive(Debug, Eq)

///|
pub fn summarize(values : Array[Double]) -> Result[ScalarStats, StatsError] {
  if values.length() == 0 {
    return Err(Empty)
  }
  let mut minimum = values[0]
  let mut maximum = values[0]
  let mut mean = 0.0
  let mut sum_absolute = 0.0
  for value in values {
    if !finite(value) {
      return Err(NonFinite)
    }
    minimum = minimum.min(value)
    maximum = maximum.max(value)
    mean += value
    sum_absolute += abs(value)
  }
  mean /= values.length().to_double()
  let mut variance = 0.0
  for value in values {
    let delta = value - mean
    variance += delta * delta
  }
  Ok({
    count: values.length(),
    minimum,
    maximum,
    mean,
    variance: variance / values.length().to_double(),
    sum: mean * values.length().to_double(),
    sum_absolute,
  })
}

///|
pub fn quantile(
  values : Array[Double],
  percentile : Double,
) -> Result[Double, StatsError] {
  if percentile < 0.0 || percentile > 1.0 || !finite(percentile) {
    return Err(InvalidQuantile)
  }
  let stats = summarize(values)
  match stats {
    Err(error) => Err(error)
    Ok(_) => {
      let ordered = values.copy()
      ordered.sort_by(fn(left, right) { left.compare(right) })
      let position = percentile * (ordered.length() - 1).to_double()
      let lower = position.to_int()
      let upper = (lower + 1).min(ordered.length() - 1)
      if lower == upper {
        Ok(ordered[lower])
      } else {
        Ok(
          ordered[lower] +
          (ordered[upper] - ordered[lower]) * (position - lower.to_double()),
        )
      }
    }
  }
}

///|
pub fn percentile_rank(
  values : Array[Double],
  value : Double,
) -> Result[Double, StatsError] {
  if !finite(value) {
    return Err(NonFinite)
  }
  if values.length() == 0 {
    return Err(Empty)
  }
  let mut less_or_equal = 0
  for item in values {
    if !finite(item) {
      return Err(NonFinite)
    }
    if item <= value {
      less_or_equal += 1
    }
  }
  Ok(less_or_equal.to_double() / values.length().to_double())
}

///|
pub fn covariance(
  left : Array[Double],
  right : Array[Double],
) -> Result[Double, StatsError] {
  if left.length() == 0 || left.length() != right.length() {
    return Err(Empty)
  }
  let left_stats = summarize(left)
  let right_stats = summarize(right)
  match (left_stats, right_stats) {
    (Ok(left_value), Ok(right_value)) => {
      let mut result = 0.0
      for index in 0..<left.length() {
        result += (left[index] - left_value.mean) *
          (right[index] - right_value.mean)
      }
      Ok(result / left.length().to_double())
    }
    (Err(error), _) => Err(error)
    (_, Err(error)) => Err(error)
  }
}

///|
pub fn correlation(
  left : Array[Double],
  right : Array[Double],
) -> Result[Double, StatsError] {
  let covariance_value = covariance(left, right)
  match (covariance_value, summarize(left), summarize(right)) {
    (Ok(value), Ok(left_stats), Ok(right_stats)) => {
      let denominator = (left_stats.variance * right_stats.variance).sqrt()
      if denominator == 0.0 {
        Ok(0.0)
      } else {
        Ok(value / denominator)
      }
    }
    (Err(error), _, _) => Err(error)
    (_, Err(error), _) => Err(error)
    (_, _, Err(error)) => Err(error)
  }
}
