///|
fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
test "photometric estimation recovers gain and bias" {
  let model = estimate_photometric([0.0, 1.0, 2.0, 3.0], [4.0, 6.0, 8.0, 10.0]).unwrap()
  assert_true(abs(model.gain - 2.0) < 0.000000001)
  assert_true(abs(model.bias - 4.0) < 0.000000001)
  assert_true(model.error < 0.000000001)
  assert_eq(apply_photometric(model, 5.0).unwrap(), 14.0)
}

///|
test "photometric estimation rejects length, constant and non-finite inputs" {
  assert_true(estimate_photometric([], []) is Err(_))
  assert_true(estimate_photometric([1.0], [1.0, 2.0]) is Err(_))
  assert_true(estimate_photometric([1.0, 1.0], [2.0, 4.0]) is Err(_))
  assert_true(estimate_photometric([0.0 / 0.0, 1.0], [1.0, 2.0]) is Err(_))
}

///|
test "patch statistics and normalization cover flat and finite patches" {
  let statistics = patch_statistics([1.0, 2.0, 3.0]).unwrap()
  assert_eq(statistics.minimum, 1.0)
  assert_eq(statistics.maximum, 3.0)
  assert_eq(statistics.mean, 2.0)
  assert_eq(statistics.dynamic_range, 2.0)
  assert_true(normalize_patch([4.0, 4.0]) is Err(ConstantSource))
  let scaled = rescale_patch([0.0, 5.0, 10.0], 0.0, 1.0).unwrap()
  assert_eq(scaled, [0.0, 0.5, 1.0])
}
