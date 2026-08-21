///|
test "batch validation aggregates gate results and reports coverage" {
  let policy = ThresholdPolicy::new(0.5, 1.0, 1.0, 1.0, 0.5).unwrap()
  let batch = batch_validation([1.0, 1.0], [0.1, 0.2], [0.1, 0.2], 4, policy).unwrap()
  assert_eq(batch.observation_count, 2)
  assert_eq(batch.acceptance_rate, 1.0)
  assert_eq(batch_label(batch), "stable")
  assert_eq(frame_coverage(batch), 0.5)
  let merged = merge_batches(batch, batch)
  assert_eq(merged.observation_count, 4)
}
