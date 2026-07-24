///|
/// A mutable, finite-safe accumulator using Welford's online variance update.
pub struct StatisticsAccumulator {
  minimum_sample_count : Int
  mut count : Int
  mut minimum : Double
  mut maximum : Double
  mut mean : Double
  mut squared_deviation_sum : Double
}

///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
/// Creates an empty accumulator governed by `config`.
pub fn StatisticsAccumulator::new(
  config : StatisticsConfig,
) -> StatisticsAccumulator {
  {
    minimum_sample_count: config.minimum_sample_count,
    count: 0,
    minimum: 0.0,
    maximum: 0.0,
    mean: 0.0,
    squared_deviation_sum: 0.0,
  }
}

///|
/// Adds one finite sample, leaving the accumulator unchanged on rejection.
pub fn StatisticsAccumulator::add(
  self : StatisticsAccumulator,
  sample : Double,
) -> Result[Unit, StatisticsError] {
  if !is_finite(sample) {
    return Err(NonFiniteSample)
  }
  let next_count = self.count + 1
  let delta = sample - self.mean
  let next_mean = self.mean + delta / next_count.to_double()
  let next_squared_deviation_sum = self.squared_deviation_sum +
    delta * (sample - next_mean)
  if !is_finite(next_mean) || !is_finite(next_squared_deviation_sum) {
    return Err(NonFiniteResult)
  }
  if self.count == 0 {
    self.minimum = sample
    self.maximum = sample
  } else {
    if sample < self.minimum {
      self.minimum = sample
    }
    if sample > self.maximum {
      self.maximum = sample
    }
  }
  self.count = next_count
  self.mean = next_mean
  self.squared_deviation_sum = next_squared_deviation_sum
  Ok(())
}

///|
/// Returns a snapshot with population variance when the reporting threshold is met.
pub fn StatisticsAccumulator::summary(
  self : StatisticsAccumulator,
) -> StatisticsSummary {
  if self.count < self.minimum_sample_count || self.count == 0 {
    {
      count: self.count,
      minimum: None,
      maximum: None,
      mean: None,
      variance: None,
    }
  } else {
    {
      count: self.count,
      minimum: Some(self.minimum),
      maximum: Some(self.maximum),
      mean: Some(self.mean),
      variance: Some(self.squared_deviation_sum / self.count.to_double()),
    }
  }
}
