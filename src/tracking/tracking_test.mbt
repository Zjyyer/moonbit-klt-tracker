///|
fn frame_or_fail(
  width : Int,
  height : Int,
  pixels : Array[Byte],
) -> @image.GrayFrame {
  @image.GrayFrame::new(width, height, pixels).unwrap()
}

///|
fn textured_frame() -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<64 {
    for x in 0..<64 {
      pixels.push(((x * 13 + y * 29 + x * y * 3) % 200 + 20).to_byte())
    }
  }
  frame_or_fail(64, 64, pixels)
}

///|
fn occlude_center(frame : @image.GrayFrame) -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      if x >= 24 && x < 40 && y >= 24 && y < 40 {
        pixels.push(0)
      } else {
        pixels.push(frame.pixels[y * frame.width + x])
      }
    }
  }
  frame_or_fail(frame.width, frame.height, pixels)
}

///|
fn seed_at(x : Double, y : Double) -> @features.SeedPoint {
  { position: @math.Vec2::{ x, y }, score: 1.0 }
}

///|
fn tracker_config(
  redetection_interval : Int,
  max_consecutive_losses : Int,
) -> TrackerConfig {
  {
    klt_config: {
      window_size: 5,
      max_iterations: 12,
      update_epsilon: 0.0001,
      minimum_eigenvalue: 1.0,
    },
    pyramid_levels: 3,
    max_consecutive_losses,
    redetection_interval,
    feature_config: {
      window_size: 3,
      minimum_score: 1.0,
      max_features: 20,
      suppression_radius: 3.0,
    },
  }
}

///|
fn tracked_observation(target : @math.Vec2) -> @klt.KltObservation {
  {
    source: @math.Vec2::{ x: 32.0, y: 32.0 },
    target,
    displacement: @math.Vec2::{ x: 0.0, y: 0.0 },
    residual: 0.0,
    minimum_eigenvalue: 1.0,
    iterations: 1,
    pyramid_level: 0,
    forward_backward_error: 0.0,
    status: @klt.Tracked,
  }
}

///|
test "a tracked observation whose target is outside the current frame is not usable" {
  assert_false(
    observation_is_trackable(
      textured_frame(),
      tracked_observation(@math.Vec2::{ x: 64.0, y: 32.0 }),
    ),
  )
}

///|
test "a tracked observation whose target is non-finite is not usable" {
  assert_false(
    observation_is_trackable(
      textured_frame(),
      tracked_observation(@math.Vec2::{ x: 1.0 / 0.0, y: 32.0 }),
    ),
  )
}

///|
test "seed IDs start at zero and retain ascending order after a frame step" {
  let frame = textured_frame()
  let tracker = Tracker::start(tracker_config(0, 2), frame, [
    seed_at(32.0, 32.0),
    seed_at(40.0, 40.0),
  ]).unwrap()
  assert_eq(tracker.tracks()[0].id, 0)
  assert_eq(tracker.tracks()[1].id, 1)
  ignore(tracker.step(frame).unwrap())
  assert_eq(tracker.tracks()[0].id, 0)
  assert_eq(tracker.tracks()[1].id, 1)
}

///|
test "a failed track enters lost once and is retained until its loss threshold" {
  let frame = textured_frame()
  let tracker = Tracker::start(tracker_config(0, 2), frame, [seed_at(1.0, 1.0)]).unwrap()
  let first = tracker.step(frame).unwrap()
  assert_eq(first.observations[0].state, Lost)
  assert_eq(tracker.tracks()[0].state, Lost)
  let second = tracker.step(frame).unwrap()
  assert_eq(second.observations[0].state, Lost)
  assert_eq(tracker.tracks().length(), 0)
}

///|
test "a rejected point does not suppress another valid observation in the same frame" {
  let frame = textured_frame()
  let tracker = Tracker::start(tracker_config(0, 2), frame, [
    seed_at(32.0, 32.0),
    seed_at(1.0, 1.0),
  ]).unwrap()
  let report = tracker.step(frame).unwrap()
  assert_eq(report.observations.length(), 2)
  assert_eq(report.observations[0].id, 0)
  assert_eq(report.observations[0].state, Active)
  assert_eq(report.observations[1].id, 1)
  assert_eq(report.observations[1].state, Lost)
}

///|
test "an occluded forward candidate is rejected by the engine forward-backward check" {
  let previous = textured_frame()
  let config : TrackerConfig = {
    klt_config: {
      window_size: 5,
      max_iterations: 1,
      update_epsilon: 0.0001,
      minimum_eigenvalue: 1.0,
    },
    pyramid_levels: 3,
    max_consecutive_losses: 2,
    redetection_interval: 0,
    feature_config: {
      window_size: 3,
      minimum_score: 1.0,
      max_features: 20,
      suppression_radius: 3.0,
    },
  }
  let next = occlude_center(previous)
  let seed = seed_at(32.0, 32.0)
  let forward = @klt.track_pyramidal(
    @image.Pyramid::build(previous, config.pyramid_levels).unwrap(),
    @image.Pyramid::build(next, config.pyramid_levels).unwrap(),
    seed,
    config.klt_config,
  )
  assert_eq(forward.status, @klt.Tracked)
  assert_true(observation_is_trackable(next, forward))
  let tracker = Tracker::start(config, previous, [seed]).unwrap()
  let report = tracker.step(next).unwrap()
  assert_eq(report.observations.length(), 1)
  assert_eq(report.observations[0].observation.status, @klt.Rejected)
  assert_eq(report.observations[0].state, Lost)
  assert_true(report.observations[0].observation.forward_backward_error >= 0.0)
  let target = report.observations[0].observation.target
  assert_false(target.x.is_nan() || target.x.is_inf())
  assert_false(target.y.is_nan() || target.y.is_inf())
  assert_eq(tracker.tracks()[0].state, Lost)
}

///|
test "redetection runs only at its configured interval and allocates fresh IDs" {
  let frame = textured_frame()
  let tracker = Tracker::start(tracker_config(2, 2), frame, []).unwrap()
  ignore(tracker.step(frame).unwrap())
  assert_eq(tracker.tracks().length(), 0)
  ignore(tracker.step(frame).unwrap())
  let redetected = tracker.tracks()
  assert_true(redetected.length() > 0)
  assert_eq(redetected[0].id, 0)
  for index in 1..<redetected.length() {
    assert_eq(redetected[index].id, index)
  }
}
