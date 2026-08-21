///|
test "scalar statistics calculate quantiles covariance and correlation" {
  let stats = summarize([1.0, 2.0, 3.0]).unwrap()
  assert_eq(stats.mean, 2.0)
  assert_eq(stats.variance, 2.0 / 3.0)
  assert_eq(quantile([1.0, 2.0, 3.0, 4.0], 0.5), Ok(2.5))
  assert_eq(percentile_rank([1.0, 2.0, 3.0], 2.0), Ok(2.0 / 3.0))
  assert_eq(covariance([1.0, 2.0], [2.0, 4.0]), Ok(0.5))
  assert_eq(correlation([1.0, 2.0], [2.0, 4.0]), Ok(1.0))
}

///|
test "scalar statistics reject empty, non-finite and invalid quantile input" {
  assert_true(summarize([]) is Err(Empty))
  assert_true(summarize([0.0 / 0.0]) is Err(NonFinite))
  assert_true(quantile([1.0], 2.0) is Err(InvalidQuantile))
  assert_true(percentile_rank([], 1.0) is Err(Empty))
}
