///|
/// Finite-safe operations over ordered numeric series.
pub(all) enum SeriesError {
  Empty
  NonFinite
  LengthMismatch
  InvalidWindow
  InvalidStep
  Degenerate
} derive(Debug, Eq)

///|
pub fn cumulative_sum(
  values : Array[Double],
) -> Result[Array[Double], SeriesError] {
  if values.length() == 0 {
    return Err(Empty)
  }
  let result : Array[Double] = []
  let mut total = 0.0
  for value in values {
    if !finite(value) {
      return Err(NonFinite)
    }
    total += value
    if !finite(total) {
      return Err(NonFinite)
    }
    result.push(total)
  }
  Ok(result)
}

///|
pub fn first_difference(
  values : Array[Double],
) -> Result[Array[Double], SeriesError] {
  if values.length() < 2 {
    return Err(InvalidStep)
  }
  let result : Array[Double] = []
  for value in values {
    if !finite(value) {
      return Err(NonFinite)
    }
  }
  for index in 1..<values.length() {
    result.push(values[index] - values[index - 1])
  }
  Ok(result)
}

///|
pub fn second_difference(
  values : Array[Double],
) -> Result[Array[Double], SeriesError] {
  match first_difference(values) {
    Err(error) => Err(error)
    Ok(first) => first_difference(first)
  }
}

///|
pub fn normalize_min_max(
  values : Array[Double],
) -> Result[Array[Double], SeriesError] {
  let stats = summarize(values)
  match stats {
    Err(_) => Err(Empty)
    Ok(value) => {
      if value.maximum == value.minimum {
        return Err(Degenerate)
      }
      let result : Array[Double] = []
      for item in values {
        result.push((item - value.minimum) / (value.maximum - value.minimum))
      }
      Ok(result)
    }
  }
}

///|
pub fn normalize_z_score(
  values : Array[Double],
) -> Result[Array[Double], SeriesError] {
  let stats = summarize(values)
  match stats {
    Err(_) => Err(Empty)
    Ok(value) => {
      if value.variance == 0.0 {
        return Err(Degenerate)
      }
      let deviation = value.variance.sqrt()
      let result : Array[Double] = []
      for item in values {
        result.push((item - value.mean) / deviation)
      }
      Ok(result)
    }
  }
}

///|
pub fn linear_regression(
  x : Array[Double],
  y : Array[Double],
) -> Result[Regression, SeriesError] {
  if x.length() < 2 || x.length() != y.length() {
    return Err(LengthMismatch)
  }
  let x_stats = summarize(x)
  let y_stats = summarize(y)
  match (x_stats, y_stats) {
    (Ok(left), Ok(right)) => {
      let mut covariance_value = 0.0
      for index in 0..<x.length() {
        covariance_value += (x[index] - left.mean) * (y[index] - right.mean)
      }
      let denominator = left.variance * x.length().to_double()
      if denominator == 0.0 {
        Err(Degenerate)
      } else {
        let slope = covariance_value / denominator
        Ok({
          slope,
          intercept: right.mean - slope * left.mean,
          coefficient: if right.variance == 0.0 {
            0.0
          } else {
            covariance_value /
            (denominator * right.variance * y.length().to_double()).sqrt()
          },
        })
      }
    }
    (Err(_), _) => Err(NonFinite)
    (_, Err(_)) => Err(NonFinite)
  }
}

///|
pub(all) struct Regression {
  slope : Double
  intercept : Double
  coefficient : Double
} derive(Debug)

///|
pub fn Regression::predict(self : Regression, x : Double) -> Double {
  self.slope * x + self.intercept
}

///|
pub fn autocorrelation(
  values : Array[Double],
  lag : Int,
) -> Result[Double, SeriesError] {
  if values.length() == 0 {
    return Err(Empty)
  }
  if lag < 0 || lag >= values.length() {
    return Err(InvalidStep)
  }
  let stats = summarize(values)
  match stats {
    Err(_) => Err(NonFinite)
    Ok(value) => {
      if value.variance == 0.0 {
        return Err(Degenerate)
      }
      let mut product = 0.0
      for index in lag..<values.length() {
        product += (values[index] - value.mean) *
          (values[index - lag] - value.mean)
      }
      Ok(product / ((values.length() - lag).to_double() * value.variance))
    }
  }
}

///|
pub fn rolling_minimum(
  values : Array[Double],
  window : Int,
) -> Result[Array[Double], SeriesError] {
  if values.length() == 0 {
    return Err(Empty)
  }
  if window < 1 || window > values.length() {
    return Err(InvalidWindow)
  }
  let result : Array[Double] = []
  for index in 0..<values.length() {
    let begin = (index + 1 - window).max(0)
    let mut minimum = values[begin]
    for cursor in begin..<(index + 1) {
      minimum = minimum.min(values[cursor])
    }
    result.push(minimum)
  }
  Ok(result)
}

///|
pub fn rolling_maximum(
  values : Array[Double],
  window : Int,
) -> Result[Array[Double], SeriesError] {
  if values.length() == 0 {
    return Err(Empty)
  }
  if window < 1 || window > values.length() {
    return Err(InvalidWindow)
  }
  let result : Array[Double] = []
  for index in 0..<values.length() {
    let begin = (index + 1 - window).max(0)
    let mut maximum = values[begin]
    for cursor in begin..<(index + 1) {
      maximum = maximum.max(values[cursor])
    }
    result.push(maximum)
  }
  Ok(result)
}

///|
pub fn interpolate_uniform(
  values : Array[Double],
  step : Double,
) -> Result[Array[Double], SeriesError] {
  if values.length() == 0 {
    return Err(Empty)
  }
  if !finite(step) || step <= 0.0 {
    return Err(InvalidStep)
  }
  for value in values {
    if !finite(value) {
      return Err(NonFinite)
    }
  }
  let result : Array[Double] = []
  result.push(values[0])
  for index in 1..<values.length() {
    let delta = values[index] - values[index - 1]
    let count = (delta.abs() / step).to_int().max(1)
    for offset in 1..<(count + 1) {
      result.push(
        values[index - 1] + delta * offset.to_double() / count.to_double(),
      )
    }
  }
  Ok(result)
}
