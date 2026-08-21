///|
test "ordered series operations cover regression and rolling boundaries" {
  assert_eq(cumulative_sum([1.0, 2.0, 3.0]), Ok([1.0, 3.0, 6.0]))
  assert_eq(first_difference([1.0, 3.0, 6.0]), Ok([2.0, 3.0]))
  assert_eq(second_difference([1.0, 3.0, 6.0]), Ok([1.0]))
  let regression = linear_regression([0.0, 1.0, 2.0], [1.0, 3.0, 5.0]).unwrap()
  assert_eq(regression.slope, 2.0)
  assert_eq(regression.predict(3.0), 7.0)
  assert_eq(rolling_minimum([3.0, 1.0, 2.0], 2).unwrap(), [3.0, 1.0, 1.0])
  assert_eq(rolling_maximum([3.0, 1.0, 2.0], 2).unwrap(), [3.0, 3.0, 2.0])
}

///|
test "ordered series operations reject empty, flat and invalid inputs" {
  assert_true(cumulative_sum([]) is Err(Empty))
  assert_true(first_difference([1.0]) is Err(InvalidStep))
  assert_true(normalize_min_max([1.0, 1.0]) is Err(Degenerate))
  assert_true(autocorrelation([1.0, 1.0], 0) is Err(Degenerate))
  assert_true(interpolate_uniform([1.0], 0.0) is Err(InvalidStep))
}
