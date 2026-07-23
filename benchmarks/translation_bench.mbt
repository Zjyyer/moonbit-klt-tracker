///|
const BENCH_WIDTH = 128

///|
const BENCH_HEIGHT = 96

///|
const BENCH_LCG_MODULUS = 65536

///|
fn bench_lcg_next(state : Int) -> Int {
  (state * 109 + 1021) % BENCH_LCG_MODULUS
}

///|
fn bench_textured_frame() -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  let mut state = 31415
  for _ in 0..<(BENCH_WIDTH * BENCH_HEIGHT) {
    state = bench_lcg_next(state)
    pixels.push((state % 200 + 20).to_byte())
  }
  @image.GrayFrame::new(BENCH_WIDTH, BENCH_HEIGHT, pixels).unwrap()
}

///|
fn bench_translate_right(frame : @image.GrayFrame) -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<BENCH_HEIGHT {
    for x in 0..<BENCH_WIDTH {
      let source_x = if x == 0 { BENCH_WIDTH - 1 } else { x - 1 }
      pixels.push(frame.pixels[y * BENCH_WIDTH + source_x])
    }
  }
  @image.GrayFrame::new(BENCH_WIDTH, BENCH_HEIGHT, pixels).unwrap()
}

///|
fn bench_feature_config() -> @features.FeatureConfig {
  {
    window_size: 3,
    minimum_score: 1.0,
    max_features: 20,
    suppression_radius: 3.0,
  }
}

///|
fn bench_tracker_config() -> @tracking.TrackerConfig {
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
    feature_config: bench_feature_config(),
  }
}

///|
test "bench detector 128x96 fixed LCG translation fixture" (it : @bench.T) {
  let frame = bench_textured_frame()
  let config = bench_feature_config()
  it.bench(fn() { it.keep(@features.detect_shi_tomasi(frame, config)) })
}

///|
test "bench tracker 128x96 fixed LCG translation fixture" (it : @bench.T) {
  let previous = bench_textured_frame()
  let next = bench_translate_right(previous)
  let config = bench_tracker_config()
  let seeds = @features.detect_shi_tomasi(previous, config.feature_config).unwrap()
  it.bench(fn() {
    let tracker = @tracking.Tracker::start(config, previous, seeds).unwrap()
    it.keep(tracker.step(next))
  })
}
