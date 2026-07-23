///|
const FIXTURE_WIDTH = 128

///|
const FIXTURE_HEIGHT = 96

///|
const FIXTURE_SEED_COUNT = 8

///|
const LCG_MODULUS = 65536

///|
fn lcg_next(state : Int) -> Int {
  (state * 109 + 1021) % LCG_MODULUS
}

///|
fn fixed_zero_motion_sequence() -> Array[@image.GrayFrame] {
  let pixels : Array[Byte] = []
  let mut state = 31415
  for _ in 0..<(FIXTURE_WIDTH * FIXTURE_HEIGHT) {
    state = lcg_next(state)
    pixels.push((state % 200 + 20).to_byte())
  }
  let frame = @image.GrayFrame::new(FIXTURE_WIDTH, FIXTURE_HEIGHT, pixels).unwrap()
  [frame, frame, frame, frame]
}

///|
fn invariant_seeds(_frame : @image.GrayFrame) -> Array[@features.SeedPoint] {
  let seeds : Array[@features.SeedPoint] = []
  let mut state = 27182
  for _ in 0..<FIXTURE_SEED_COUNT {
    state = lcg_next(state)
    let x = (20 + state % 88).to_double()
    state = lcg_next(state)
    let y = (20 + state % 56).to_double()
    seeds.push({ position: @math.Vec2::{ x, y }, score: 1.0 })
  }
  seeds
}

///|
fn invariant_tracker_config() -> @tracking.TrackerConfig {
  {
    klt_config: {
      window_size: 5,
      max_iterations: 12,
      update_epsilon: 0.0001,
      minimum_eigenvalue: 1.0,
    },
    pyramid_levels: 3,
    max_consecutive_losses: 3,
    redetection_interval: 0,
    feature_config: {
      window_size: 3,
      minimum_score: 1.0,
      max_features: 20,
      suppression_radius: 3.0,
    },
  }
}

///|
test "deterministic zero-motion tracking keeps public invariants" {
  let sequence = fixed_zero_motion_sequence()
  let tracker = @tracking.Tracker::start(
    invariant_tracker_config(),
    sequence[0],
    invariant_seeds(sequence[0]),
  ).unwrap()
  let initial_ids : Array[Int] = []
  for track in tracker.tracks() {
    initial_ids.push(track.id)
  }
  let mut prior_frame_index = 0
  for index in 1..<sequence.length() {
    let report = tracker.step(sequence[index]).unwrap()
    assert_true(report.frame_index > prior_frame_index)
    prior_frame_index = report.frame_index
    assert_eq(report.observations.length(), FIXTURE_SEED_COUNT)
    for observation_index, item in report.observations {
      assert_eq(item.id, initial_ids[observation_index])
      assert_eq(item.state, @tracking.Active)
      let target = item.observation.target
      assert_false(target.x.is_nan() || target.x.is_inf())
      assert_false(target.y.is_nan() || target.y.is_inf())
      assert_true(target.x >= 0.0 && target.x <= 127.0)
      assert_true(target.y >= 0.0 && target.y <= 95.0)
      let displacement = item.observation.displacement
      assert_true(displacement.x.abs() <= 0.01)
      assert_true(displacement.y.abs() <= 0.01)
    }
  }
}
