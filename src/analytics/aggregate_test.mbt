///|
test "scalar aggregation tracks finite moments and histogram percentiles" {
  let histogram = Histogram::new(0.0, 10.0, 5).unwrap()
  let aggregate = ScalarAggregate::new(histogram)
  aggregate.add(1.0).unwrap()
  aggregate.add(3.0).unwrap()
  aggregate.add(5.0).unwrap()
  assert_eq(aggregate.count, 3)
  assert_eq(aggregate.mean, 3.0)
  assert_true(aggregate.standard_deviation() > 1.6)
  assert_true(aggregate.histogram.percentile(0.5).unwrap() > 2.0)
}

///|
test "aggregation helpers handle empty, weighted and smoothing boundaries" {
  assert_true(summarize_scalars([]) is Err(EmptyInput))
  assert_eq(weighted_mean([1.0, 3.0], [1.0, 3.0]), Ok(2.5))
  assert_true(weighted_mean([1.0], [0.0]) is Err(EmptyInput))
  assert_eq(moving_average([1.0, 2.0, 3.0], 2).unwrap(), [1.0, 1.5, 2.5])
  assert_eq(exponential_average([1.0, 3.0], 0.5).unwrap(), [1.0, 2.0])
}
