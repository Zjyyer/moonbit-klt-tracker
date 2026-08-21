///|
test "motion metrics report path, turning and aggregate values" {
  let trajectory = Trajectory::new(1, [
    { frame: 0, position: { x: 0.0, y: 0.0 }, confidence: 1.0, state: Accepted },
    { frame: 1, position: { x: 1.0, y: 0.0 }, confidence: 1.0, state: Accepted },
    { frame: 2, position: { x: 1.0, y: 1.0 }, confidence: 1.0, state: Accepted },
  ]).unwrap()
  let metrics = trajectory.metrics()
  assert_eq(metrics.duration, 2)
  assert_eq(metrics.observed_frames, 3)
  assert_eq(metrics.path_length, 2.0)
  assert_true(metrics.heading_change > 1.5)
  let aggregate = aggregate_metrics([trajectory])
  assert_eq(aggregate.trajectory_count, 1)
  assert_eq(aggregate.total_observed_frames, 3)
}
