///|
test "threshold gates report rates and dominant failure classes" {
  let policy = ThresholdPolicy::new(0.5, 1.0, 2.0, 1.0, 0.5).unwrap()
  let result = evaluate_gate(
    [1.0, 0.1, 1.0, 1.0],
    [0.1, 0.1, 2.0, 0.1],
    [1.0, 1.0, 1.0, 3.0],
    [0.1, 0.1, 0.1, 0.1],
    policy,
  ).unwrap()
  assert_eq(result.total, 4)
  assert_eq(result.passed, 1)
  assert_eq(result.texture_failures, 1)
  assert_eq(result.residual_failures, 1)
  assert_eq(result.velocity_failures, 1)
  assert_eq(quality_label(result), "rejected")
  assert_eq(dominant_failure(result), "texture")
  assert_true(require_gate(result) is Err(FailedGate))
}

///|
test "threshold gates reject malformed inputs and merge batches" {
  assert_true(
    ThresholdPolicy::new(0.0, 1.0, 1.0, 1.0, 2.0) is Err(InvalidValue),
  )
  let policy = ThresholdPolicy::new(0.0, 1.0, 1.0, 1.0, 0.0).unwrap()
  assert_true(evaluate_gate([], [], [], [], policy) is Err(EmptyMeasurements))
  assert_true(
    evaluate_gate([1.0], [], [1.0], [1.0], policy) is Err(LengthMismatch),
  )
  let first = evaluate_gate([1.0], [0.0], [0.0], [0.0], policy).unwrap()
  let merged = merge_gate_results(first, first)
  assert_eq(merged.total, 2)
  assert_eq(merged.acceptance_rate, 1.0)
}
