///|
test "statistics summary for no samples has no extrema or moments" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  )
  let summary = accumulator.summary()
  assert_eq(summary.count, 0)
  assert_eq(summary.minimum, None)
  assert_eq(summary.maximum, None)
  assert_eq(summary.mean, None)
  assert_eq(summary.variance, None)
}

///|
test "statistics summary for one finite sample has zero population variance" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  )
  accumulator.add(4.5).unwrap()
  let summary = accumulator.summary()
  assert_eq(summary.count, 1)
  assert_eq(summary.minimum, Some(4.5))
  assert_eq(summary.maximum, Some(4.5))
  assert_eq(summary.mean, Some(4.5))
  assert_eq(summary.variance, Some(0.0))
}

///|
test "statistics accumulator calculates finite extrema mean and variance" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  )
  accumulator.add(1.0).unwrap()
  accumulator.add(2.0).unwrap()
  accumulator.add(3.0).unwrap()
  let summary = accumulator.summary()
  assert_eq(summary.count, 3)
  assert_eq(summary.minimum, Some(1.0))
  assert_eq(summary.maximum, Some(3.0))
  assert_eq(summary.mean, Some(2.0))
  assert_eq(summary.variance, Some(2.0 / 3.0))
}

///|
test "statistics rejects non-finite samples without changing its summary" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  )
  assert_eq(accumulator.add(0.0 / 0.0), Err(NonFiniteSample))
  assert_eq(accumulator.summary().count, 0)
}

///|
test "statistics configuration rejects a negative minimum sample count" {
  assert_eq(StatisticsConfig::new(-1), Err(InvalidMinimumSampleCount))
}
