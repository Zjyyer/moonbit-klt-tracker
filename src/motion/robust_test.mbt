///|
fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
test "robust losses down-weight outliers and compute finite medians" {
  let config = RobustConfig::new(Huber, 1.0, 12, 0.000001).unwrap()
  assert_eq(robust_weight(config, 0.5), 1.0)
  assert_eq(robust_weight(config, 4.0), 0.25)
  assert_eq(median([1.0, 100.0, 2.0]), Ok(2.0))
  assert_eq(median_absolute_deviation([1.0, 2.0, 3.0]), Ok(1.4826))
}

///|
test "robust location resists a large finite outlier" {
  let config = RobustConfig::new(Tukey, 1.0, 20, 0.000001).unwrap()
  let location = robust_location([1.0, 1.1, 0.9, 1.0, 100.0], config).unwrap()
  assert_true(abs(location - 1.0) < 0.1)
  let summary = summarize_robust([1.0, 1.1, 0.9, 100.0], config).unwrap()
  assert_true(summary.outlier_count >= 1)
}
