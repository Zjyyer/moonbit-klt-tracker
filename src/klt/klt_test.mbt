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
  for y in 0..<11 {
    for x in 0..<11 {
      pixels.push(((x * 17 + y * 31 + x * y * 7) % 200 + 20).to_byte())
    }
  }
  frame_or_fail(11, 11, pixels)
}

///|
fn shifted_right(frame : @image.GrayFrame) -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      let source_x = if x == 0 { 0 } else { x - 1 }
      pixels.push(frame.pixels[y * frame.width + source_x])
    }
  }
  frame_or_fail(frame.width, frame.height, pixels)
}

///|
fn solver_config() -> KltConfig {
  {
    window_size: 5,
    max_iterations: 12,
    update_epsilon: 0.0001,
    minimum_eigenvalue: 1.0,
  }
}

///|
fn seed_at(x : Double, y : Double) -> @features.SeedPoint {
  { position: @math.Vec2::{ x, y }, score: 1.0 }
}

///|
fn assert_finite_neutral_rejection(observation : KltObservation) -> Unit raise {
  assert_eq(observation.status, Rejected)
  assert_true(!observation.source.x.is_nan() && !observation.source.x.is_inf())
  assert_true(!observation.source.y.is_nan() && !observation.source.y.is_inf())
  assert_true(
    !observation.displacement.x.is_nan() && !observation.displacement.x.is_inf(),
  )
  assert_true(
    !observation.displacement.y.is_nan() && !observation.displacement.y.is_inf(),
  )
  assert_true(!observation.target.x.is_nan() && !observation.target.x.is_inf())
  assert_true(!observation.target.y.is_nan() && !observation.target.y.is_inf())
  assert_eq(observation.displacement.x, 0.0)
  assert_eq(observation.displacement.y, 0.0)
  assert_eq(observation.target.x, 0.0)
  assert_eq(observation.target.y, 0.0)
}

///|
test "single-level KLT returns a finite neutral rejection for non-finite seed coordinates" {
  let previous = textured_frame()
  let observation = track_single_level(
    previous,
    previous,
    @image.GradientFrame::from_frame(previous),
    seed_at(0.0 / 0.0, 5.0),
    @math.Vec2::{ x: 0.0, y: 0.0 },
    solver_config(),
  )
  assert_finite_neutral_rejection(observation)
}

///|
test "single-level KLT returns a finite neutral rejection for non-finite initial displacement" {
  let previous = textured_frame()
  let observation = track_single_level(
    previous,
    previous,
    @image.GradientFrame::from_frame(previous),
    seed_at(5.0, 5.0),
    @math.Vec2::{ x: 1.0 / 0.0, y: 0.0 },
    solver_config(),
  )
  assert_finite_neutral_rejection(observation)
}

///|
test "single-level KLT recovers a one-pixel right translation within 0.01 pixels" {
  let previous = textured_frame()
  let next = shifted_right(previous)
  let observation = track_single_level(
    previous,
    next,
    @image.GradientFrame::from_frame(previous),
    seed_at(5.0, 5.0),
    @math.Vec2::{ x: 0.0, y: 0.0 },
    solver_config(),
  )
  assert_eq(observation.status, Tracked)
  assert_true((observation.displacement.x - 1.0).abs() <= 0.01)
  assert_true(observation.displacement.y.abs() <= 0.01)
  assert_true(observation.iterations <= 12)
}

///|
test "single-level KLT rejects a flat window for poor conditioning" {
  let flat = frame_or_fail(11, 11, Array::make(121, 42))
  let observation = track_single_level(
    flat,
    flat,
    @image.GradientFrame::from_frame(flat),
    seed_at(5.0, 5.0),
    @math.Vec2::{ x: 0.0, y: 0.0 },
    solver_config(),
  )
  assert_eq(observation.status, Rejected)
  assert_true(observation.minimum_eigenvalue < 1.0)
}

///|
test "single-level KLT reports out-of-bounds for a target window outside the frame" {
  let previous = textured_frame()
  let observation = track_single_level(
    previous,
    previous,
    @image.GradientFrame::from_frame(previous),
    seed_at(5.0, 5.0),
    @math.Vec2::{ x: 5.0, y: 0.0 },
    solver_config(),
  )
  assert_eq(observation.status, OutOfBounds)
  assert_true(observation.minimum_eigenvalue > 1.0)
}
