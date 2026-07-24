///|
/// Errors raised while validating analytics inputs or deriving finite statistics.
pub(all) enum StatisticsError {
  InvalidMinimumSampleCount
  NonFiniteSample
  NonFiniteResult
} derive(Debug, Eq)

///|
/// Controls when a summary exposes its finite moments.
pub(all) struct StatisticsConfig {
  minimum_sample_count : Int
} derive(Debug, Eq)

///|
fn valid_minimum_sample_count(minimum_sample_count : Int) -> Bool {
  minimum_sample_count >= 0
}

///|
/// Creates a statistics configuration with a non-negative reporting threshold.
pub fn StatisticsConfig::new(
  minimum_sample_count : Int,
) -> Result[StatisticsConfig, StatisticsError] {
  if !valid_minimum_sample_count(minimum_sample_count) {
    Err(InvalidMinimumSampleCount)
  } else {
    Ok({ minimum_sample_count, })
  }
}

///|
/// Immutable descriptive statistics for accepted finite samples.
pub(all) struct StatisticsSummary {
  count : Int
  minimum : Double?
  maximum : Double?
  mean : Double?
  variance : Double?
} derive(Debug)
