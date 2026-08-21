///|
/// A bounded histogram for frame-level quality dashboards.
pub(all) struct Histogram {
  minimum : Double
  maximum : Double
  buckets : Array[Int]
  mut underflow : Int
  mut overflow : Int
  mut count : Int
} derive(Debug)

///|
pub(all) enum AggregateError {
  InvalidBucketCount
  InvalidRange
  NonFiniteValue
  EmptyInput
} derive(Debug, Eq)

///|
pub fn Histogram::new(
  minimum : Double,
  maximum : Double,
  bucket_count : Int,
) -> Result[Histogram, AggregateError] {
  if bucket_count < 1 {
    return Err(InvalidBucketCount)
  }
  if !finite(minimum) || !finite(maximum) || minimum >= maximum {
    return Err(InvalidRange)
  }
  let buckets : Array[Int] = []
  for _ in 0..<bucket_count {
    buckets.push(0)
  }
  Ok({ minimum, maximum, buckets, underflow: 0, overflow: 0, count: 0 })
}

///|
pub fn Histogram::add(
  self : Histogram,
  value : Double,
) -> Result[Unit, AggregateError] {
  if !finite(value) {
    return Err(NonFiniteValue)
  }
  self.count += 1
  if value < self.minimum {
    self.underflow += 1
  } else if value >= self.maximum {
    self.overflow += 1
  } else {
    let width = (self.maximum - self.minimum) /
      self.buckets.length().to_double()
    let mut index = ((value - self.minimum) / width).to_int()
    if index >= self.buckets.length() {
      index = self.buckets.length() - 1
    }
    self.buckets[index] += 1
  }
  Ok(())
}

///|
pub fn Histogram::percentile(self : Histogram, percentile : Double) -> Double? {
  if percentile < 0.0 || percentile > 1.0 || self.count == 0 {
    return None
  }
  if self.underflow > 0 && percentile == 0.0 {
    return Some(self.minimum)
  }
  let wanted = (self.count - 1).to_double() * percentile
  let target = wanted.to_int()
  let mut cumulative = self.underflow
  for index, bucket in self.buckets {
    cumulative += bucket
    if cumulative > target {
      let width = (self.maximum - self.minimum) /
        self.buckets.length().to_double()
      return Some(self.minimum + (index.to_double() + 0.5) * width)
    }
  }
  Some(self.maximum)
}

///|
/// A finite-safe aggregate over scalar observations.
pub(all) struct ScalarAggregate {
  mut count : Int
  mut minimum : Double?
  mut maximum : Double?
  mut mean : Double
  mut variance : Double
  mut sum : Double
  histogram : Histogram
} derive(Debug)

///|
pub fn ScalarAggregate::new(histogram : Histogram) -> ScalarAggregate {
  {
    count: 0,
    minimum: None,
    maximum: None,
    mean: 0.0,
    variance: 0.0,
    sum: 0.0,
    histogram,
  }
}

///|
pub fn ScalarAggregate::add(
  self : ScalarAggregate,
  value : Double,
) -> Result[Unit, AggregateError] {
  if !finite(value) {
    return Err(NonFiniteValue)
  }
  let next_count = self.count + 1
  let delta = value - self.mean
  let next_mean = self.mean + delta / next_count.to_double()
  let next_variance = self.variance + delta * (value - next_mean)
  if !finite(next_mean) || !finite(next_variance) {
    return Err(NonFiniteValue)
  }
  match self.minimum {
    Some(current) => if value < current { self.minimum = Some(value) }
    None => self.minimum = Some(value)
  }
  match self.maximum {
    Some(current) => if value > current { self.maximum = Some(value) }
    None => self.maximum = Some(value)
  }
  self.count = next_count
  self.mean = next_mean
  self.variance = next_variance
  self.sum += value
  self.histogram.add(value)
}

///|
pub fn ScalarAggregate::population_variance(self : ScalarAggregate) -> Double {
  if self.count == 0 {
    0.0
  } else {
    self.variance / self.count.to_double()
  }
}

///|
pub fn ScalarAggregate::standard_deviation(self : ScalarAggregate) -> Double {
  self.population_variance().sqrt()
}

///|
pub fn ScalarAggregate::coefficient_of_variation(
  self : ScalarAggregate,
) -> Double? {
  if self.count == 0 || self.mean == 0.0 {
    None
  } else {
    Some(self.standard_deviation() / abs(self.mean))
  }
}

///|
/// Returns a deterministic scalar summary over values.
pub fn summarize_scalars(
  values : Array[Double],
) -> Result[ScalarAggregate, AggregateError] {
  if values.length() == 0 {
    return Err(EmptyInput)
  }
  let histogram = Histogram::new(0.0, 1.0, 10).unwrap()
  let aggregate = ScalarAggregate::new(histogram)
  for value in values {
    match aggregate.add(value) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(aggregate)
}

///|
/// Computes a weighted mean with finite validation.
pub fn weighted_mean(
  values : Array[Double],
  weights : Array[Double],
) -> Result[Double, AggregateError] {
  if values.length() == 0 || values.length() != weights.length() {
    return Err(EmptyInput)
  }
  let mut weighted_sum = 0.0
  let mut total_weight = 0.0
  for index in 0..<values.length() {
    if !finite(values[index]) || !finite(weights[index]) || weights[index] < 0.0 {
      return Err(NonFiniteValue)
    }
    weighted_sum += values[index] * weights[index]
    total_weight += weights[index]
  }
  if total_weight == 0.0 {
    Err(EmptyInput)
  } else {
    Ok(weighted_sum / total_weight)
  }
}

///|
/// Computes a normalized exponential moving average.
pub fn exponential_average(
  values : Array[Double],
  smoothing : Double,
) -> Result[Array[Double], AggregateError] {
  if values.length() == 0 {
    return Err(EmptyInput)
  }
  if smoothing < 0.0 || smoothing > 1.0 || !finite(smoothing) {
    return Err(InvalidRange)
  }
  let result : Array[Double] = []
  let mut state = values[0]
  if !finite(state) {
    return Err(NonFiniteValue)
  }
  result.push(state)
  for value in values[1:] {
    if !finite(value) {
      return Err(NonFiniteValue)
    }
    state = smoothing * value + (1.0 - smoothing) * state
    result.push(state)
  }
  Ok(result)
}

///|
pub fn moving_average(
  values : Array[Double],
  window : Int,
) -> Result[Array[Double], AggregateError] {
  if values.length() == 0 {
    return Err(EmptyInput)
  }
  if window < 1 || window > values.length() {
    return Err(InvalidRange)
  }
  let result : Array[Double] = []
  let mut sum = 0.0
  for index in 0..<values.length() {
    if !finite(values[index]) {
      return Err(NonFiniteValue)
    }
    sum += values[index]
    if index >= window {
      sum -= values[index - window]
    }
    let divisor = if index + 1 < window { index + 1 } else { window }
    result.push(sum / divisor.to_double())
  }
  Ok(result)
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}
