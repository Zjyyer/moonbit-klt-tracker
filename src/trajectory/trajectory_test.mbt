///|
fn sample(
  frame : Int,
  x : Double,
  y : Double,
  state : PointState,
) -> TrajectoryPoint {
  { frame, position: { x, y }, confidence: 1.0, state }
}

///|
test "trajectory sorts points and computes displacement" {
  let trajectory = Trajectory::new(7, [
    sample(3, 6.0, 4.0, Accepted),
    sample(1, 0.0, 0.0, Accepted),
    sample(2, 3.0, 4.0, Accepted),
  ]).unwrap()
  assert_eq(trajectory.first_frame(), Some(1))
  assert_eq(trajectory.last_frame(), Some(3))
  assert_true(abs(trajectory.displacement() - 7.2111025509) < 0.000000001)
  assert_eq(trajectory.gap_count(), 0)
}

///|
test "resampling fills gaps only inside a valid interval" {
  let trajectory = Trajectory::new(3, [
    sample(0, 0.0, 0.0, Accepted),
    sample(2, 4.0, 0.0, Accepted),
  ]).unwrap()
  let resampled = trajectory.resample(1).unwrap()
  assert_eq(resampled.points.length(), 3)
  assert_eq(resampled.points[1].frame, 1)
  assert_eq(resampled.points[1].position.x, 2.0)
  assert_eq(resampled.gap_count(), 0)
}

///|
test "quality and events handle lost points and threshold boundaries" {
  let trajectory = Trajectory::new(4, [
    sample(0, 0.0, 0.0, Accepted),
    sample(1, 1.0, 0.0, Lost),
    sample(3, 5.0, 0.0, Accepted),
  ]).unwrap()
  let quality = trajectory.quality(QualityConfig::new(1.0, 2.0).unwrap())
  assert_eq(quality.total_count, 3)
  assert_eq(quality.accepted_count, 2)
  assert_eq(quality.lost_count, 1)
  assert_eq(quality.max_speed, 2.0)
  let events = lifecycle_events([trajectory])
  assert_eq(events.length(), 3)
  assert_eq(events[0], Activated(id=4, frame=0))
  assert_eq(events[1], Lost(id=4, frame=1))
  assert_eq(events[2], Recovered(id=4, frame=3))
}

///|
test "invalid trajectory input is rejected without hidden sorting changes" {
  assert_true(Trajectory::new(-1, []) is Err(_))
  assert_true(
    Trajectory::new(1, [sample(0, 0.0 / 0.0, 1.0, Accepted)]) is Err(_),
  )
  let one = Trajectory::new(1, [sample(0, 1.0, 2.0, Accepted)]).unwrap()
  assert_eq(one.speed(), 0.0)
  assert_eq(one.acceleration(), 0.0)
}
