///|
test "statistics summary for no samples has no extrema or moments" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  let summary = accumulator.summary()
  assert_eq(summary.count, 0)
  assert_eq(summary.minimum, None)
  assert_eq(summary.maximum, None)
  assert_eq(summary.mean, None)
  assert_eq(summary.variance, None)
}

///|
test "statistics summary for one finite sample has zero population variance" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  accumulator.add(4.5).unwrap()
  let summary = accumulator.summary()
  assert_eq(summary.count, 1)
  assert_eq(summary.minimum, Some(4.5))
  assert_eq(summary.maximum, Some(4.5))
  assert_eq(summary.mean, Some(4.5))
  assert_eq(summary.variance, Some(0.0))
}

///|
test "statistics accumulator calculates finite extrema mean and variance" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  accumulator.add(1.0).unwrap()
  accumulator.add(2.0).unwrap()
  accumulator.add(3.0).unwrap()
  let summary = accumulator.summary()
  assert_eq(summary.count, 3)
  assert_eq(summary.minimum, Some(1.0))
  assert_eq(summary.maximum, Some(3.0))
  assert_eq(summary.mean, Some(2.0))
  assert_eq(summary.variance, Some(2.0 / 3.0))
}

///|
test "statistics rejects non-finite samples without changing its summary" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  assert_eq(accumulator.add(0.0 / 0.0), Err(NonFiniteSample))
  assert_eq(accumulator.summary().count, 0)
}

///|
test "statistics configuration rejects a negative minimum sample count" {
  assert_eq(StatisticsConfig::new(-1), Err(InvalidMinimumSampleCount))
}

///|
test "statistics accumulator validates directly constructed configurations" {
  let invalid : StatisticsConfig = { minimum_sample_count: -1 }
  match StatisticsAccumulator::new(invalid) {
    Err(error) => assert_eq(error, InvalidMinimumSampleCount)
    Ok(_) => fail("expected invalid configuration to be rejected")
  }
}

///|
test "statistics threshold hides moments until enough samples arrive" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(2).unwrap(),
  ).unwrap()
  accumulator.add(1.0).unwrap()
  let hidden = accumulator.summary()
  assert_eq(hidden.count, 1)
  assert_eq(hidden.minimum, None)
  assert_eq(hidden.maximum, None)
  assert_eq(hidden.mean, None)
  assert_eq(hidden.variance, None)
  accumulator.add(3.0).unwrap()
  let exposed = accumulator.summary()
  assert_eq(exposed.count, 2)
  assert_eq(exposed.minimum, Some(1.0))
  assert_eq(exposed.maximum, Some(3.0))
  assert_eq(exposed.mean, Some(2.0))
  assert_eq(exposed.variance, Some(1.0))
}

///|
test "statistics rejects NaN and infinity without changing a populated summary" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  accumulator.add(2.0).unwrap()
  let before = accumulator.summary()
  assert_eq(accumulator.add(0.0 / 0.0), Err(NonFiniteSample))
  assert_eq(accumulator.add(1.0 / 0.0), Err(NonFiniteSample))
  let after = accumulator.summary()
  assert_eq(after.count, before.count)
  assert_eq(after.minimum, before.minimum)
  assert_eq(after.maximum, before.maximum)
  assert_eq(after.mean, before.mean)
  assert_eq(after.variance, before.variance)
}

///|
test "statistics rejects finite overflow without changing a populated summary" {
  let accumulator = StatisticsAccumulator::new(
    StatisticsConfig::new(0).unwrap(),
  ).unwrap()
  accumulator.add(1.0e308).unwrap()
  let before = accumulator.summary()
  assert_eq(accumulator.add(-1.0e308), Err(NonFiniteResult))
  let after = accumulator.summary()
  assert_eq(after.count, before.count)
  assert_eq(after.minimum, before.minimum)
  assert_eq(after.maximum, before.maximum)
  assert_eq(after.mean, before.mean)
  assert_eq(after.variance, before.variance)
}

///|
fn analytics_observation(
  target_x : Double,
  target_y : Double,
  residual : Double,
  forward_backward_error : Double,
  status : @klt.KltStatus,
) -> @klt.KltObservation {
  {
    source: @math.Vec2::{ x: 0.0, y: 0.0 },
    target: @math.Vec2::{ x: target_x, y: target_y },
    displacement: @math.Vec2::{ x: target_x, y: target_y },
    residual,
    minimum_eigenvalue: 1.0,
    iterations: 1,
    pyramid_level: 0,
    forward_backward_error,
    status,
  }
}

///|
fn analytics_report(
  frame_index : Int,
  observations : Array[@tracking.TrackObservation],
) -> @tracking.FrameReport {
  { frame_index, observations }
}

///|
test "analysis summarizes displacement velocity quality ranking and anomalies" {
  let document = @formats.TrajectoryDocument::new([], [
    analytics_report(3, [
      {
        id: 2,
        state: @tracking.Lost,
        observation: analytics_observation(3.0, 4.0, 0.1, 0.1, @klt.Rejected),
      },
      {
        id: 1,
        state: @tracking.Active,
        observation: analytics_observation(1.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
    ]),
    analytics_report(1, [
      {
        id: 2,
        state: @tracking.Active,
        observation: analytics_observation(0.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
      {
        id: 1,
        state: @tracking.Active,
        observation: analytics_observation(0.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
    ]),
  ])
  let analysis = analyze(document, AnalysisConfig::new(2.0, 0.5).unwrap()).unwrap()
  assert_eq(analysis.quality.observation_count, 4)
  assert_eq(analysis.quality.active_count, 3)
  assert_eq(analysis.quality.lost_count, 1)
  assert_eq(analysis.quality.rejected_count, 1)
  assert_eq(analysis.tracks.length(), 2)
  let first = analysis.tracks[0]
  assert_eq(first.id, 1)
  assert_eq(first.displacement, 1.0)
  assert_eq(first.mean_velocity, 0.5)
  assert_eq(first.rank, 2)
  assert_eq(first.anomaly, Normal)
  let second = analysis.tracks[1]
  assert_eq(second.id, 2)
  assert_eq(second.displacement, 5.0)
  assert_eq(second.mean_velocity, 2.5)
  assert_eq(second.rank, 1)
  assert_eq(second.anomaly, ExcessiveVelocity)
}

///|
test "analysis emits sorted active and lost lifecycle transitions" {
  let document = @formats.TrajectoryDocument::new([], [
    analytics_report(2, [
      {
        id: 7,
        state: @tracking.Lost,
        observation: analytics_observation(1.0, 0.0, 0.1, 0.1, @klt.OutOfBounds),
      },
    ]),
    analytics_report(1, [
      {
        id: 7,
        state: @tracking.Active,
        observation: analytics_observation(1.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
    ]),
    analytics_report(3, [
      {
        id: 7,
        state: @tracking.Active,
        observation: analytics_observation(2.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
    ]),
  ])
  let analysis = analyze(document, AnalysisConfig::new(10.0, 1.0).unwrap()).unwrap()
  assert_eq(analysis.events, [
    Activated(id=7, frame=1),
    Lost(id=7, frame=2),
    Activated(id=7, frame=3),
  ])
}

///|
test "analysis breaks equal displacement ranking ties by track ID" {
  let document = @formats.TrajectoryDocument::new([], [
    analytics_report(1, [
      {
        id: 9,
        state: @tracking.Active,
        observation: analytics_observation(2.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
      {
        id: 4,
        state: @tracking.Active,
        observation: analytics_observation(2.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
    ]),
  ])
  let analysis = analyze(document, AnalysisConfig::new(10.0, 1.0).unwrap()).unwrap()
  assert_eq(analysis.tracks[0].id, 4)
  assert_eq(analysis.tracks[0].rank, 1)
  assert_eq(analysis.tracks[1].id, 9)
  assert_eq(analysis.tracks[1].rank, 2)
}

///|
test "analysis orders equal-displacement extreme ID ties without overflow" {
  let smallest = -2147483648
  let largest = 2147483647
  let document = @formats.TrajectoryDocument::new([], [
    analytics_report(1, [
      {
        id: largest,
        state: @tracking.Active,
        observation: analytics_observation(2.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
      {
        id: smallest,
        state: @tracking.Active,
        observation: analytics_observation(2.0, 0.0, 0.1, 0.1, @klt.Tracked),
      },
    ]),
  ])
  let analysis = analyze(document, AnalysisConfig::new(10.0, 1.0).unwrap()).unwrap()
  assert_eq(analysis.tracks[0].id, smallest)
  assert_eq(analysis.tracks[0].rank, 1)
  assert_eq(analysis.tracks[1].id, largest)
  assert_eq(analysis.tracks[1].rank, 2)
}

///|
test "analysis classifies residual anomalies before velocity anomalies" {
  let document = @formats.TrajectoryDocument::new([], [
    analytics_report(1, [
      {
        id: 3,
        state: @tracking.Active,
        observation: analytics_observation(9.0, 0.0, 2.0, 0.1, @klt.Tracked),
      },
    ]),
  ])
  let analysis = analyze(document, AnalysisConfig::new(1.0, 1.0).unwrap()).unwrap()
  assert_eq(analysis.tracks[0].anomaly, ExcessiveResidual)
}
