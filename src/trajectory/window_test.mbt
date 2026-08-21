///|
test "trajectory windows expose coverage, bounds and deterministic nearest points" {
  let trajectory = Trajectory::new(1, [
    { frame: 0, position: { x: 0.0, y: 0.0 }, confidence: 1.0, state: Accepted },
    { frame: 2, position: { x: 2.0, y: 0.0 }, confidence: 0.5, state: Accepted },
    { frame: 3, position: { x: 3.0, y: 1.0 }, confidence: 1.0, state: Accepted },
  ]).unwrap()
  let window = trajectory.window(0, 3).unwrap()
  assert_eq(window.points.length(), 3)
  assert_eq(window.coverage, 0.75)
  assert_true(window.continuity < 1.0)
  assert_eq(trajectory.nearest({ x: 2.1, y: 0.0 }).frame, 2)
  assert_eq(trajectory.coordinate_summary().area, 3.0)
  assert_eq(trajectory.downsample(2).unwrap().points.length(), 2)
}
