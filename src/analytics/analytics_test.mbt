///|
test "statistics summary for no samples has no extrema or moments" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
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
  ).unwrap()
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
  ).unwrap()
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
  ).unwrap()
  assert_eq(accumulator.add(0.0 / 0.0), Err(NonFiniteSample))
  assert_eq(accumulator.summary().count, 0)
}

///|
test "statistics configuration rejects a negative minimum sample count" {
  assert_eq(StatisticsConfig::new(-1), Err(InvalidMinimumSampleCount))
}

///|
test "statistics accumulator validates directly constructed configurations" {
  let invalid : StatisticsConfig = { minimum_sample_count: -1 }
  match StatisticsAccumulator::new(invalid) {
    Err(error) => assert_eq(error, InvalidMinimumSampleCount)
    Ok(_) => fail("expected invalid configuration to be rejected")
  }
}

///|
test "statistics threshold hides moments until enough samples arrive" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(2).unwrap(),
  ).unwrap()
  accumulator.add(1.0).unwrap()
  let hidden = accumulator.summary()
  assert_eq(hidden.count, 1)
  assert_eq(hidden.minimum, None)
  assert_eq(hidden.maximum, None)
  assert_eq(hidden.mean, None)
  assert_eq(hidden.variance, None)
  accumulator.add(3.0).unwrap()
  let exposed = accumulator.summary()
  assert_eq(exposed.count, 2)
  assert_eq(exposed.minimum, Some(1.0))
  assert_eq(exposed.maximum, Some(3.0))
  assert_eq(exposed.mean, Some(2.0))
  assert_eq(exposed.variance, Some(1.0))
}

///|
test "statistics rejects NaN and infinity without changing a populated summary" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  accumulator.add(2.0).unwrap()
  let before = accumulator.summary()
  assert_eq(accumulator.add(0.0 / 0.0), Err(NonFiniteSample))
  assert_eq(accumulator.add(1.0 / 0.0), Err(NonFiniteSample))
  let after = accumulator.summary()
  assert_eq(after.count, before.count)
  assert_eq(after.minimum, before.minimum)
  assert_eq(after.maximum, before.maximum)
  assert_eq(after.mean, before.mean)
  assert_eq(after.variance, before.variance)
}

///|
test "statistics rejects finite overflow without changing a populated summary" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  accumulator.add(1.0e308).unwrap()
  let before = accumulator.summary()
  assert_eq(accumulator.add(-1.0e308), Err(NonFiniteResult))
  let after = accumulator.summary()
  assert_eq(after.count, before.count)
  assert_eq(after.minimum, before.minimum)
  assert_eq(after.maximum, before.maximum)
  assert_eq(after.mean, before.mean)
  assert_eq(after.variance, before.variance)
}
