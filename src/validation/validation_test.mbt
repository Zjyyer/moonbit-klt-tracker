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
fn shifted_right_by(frame : @image.GrayFrame, amount : Int) -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      let source_x = if x < amount { 0 } else { x - amount }
      pixels.push(frame.pixels[y * frame.width + source_x])
    }
  }
  frame_or_fail(frame.width, frame.height, pixels)
}

///|
fn seed_at(x : Double, y : Double) -> @features.SeedPoint {
  { position: { x, y }, score: 1.0 }
}

///|
fn solver_config() -> @klt.KltConfig {
  {
    window_size: 5,
    max_iterations: 12,
    update_epsilon: 0.0001,
    minimum_eigenvalue: 1.0,
  }
}

///|
test "forward-backward validation rejects inconsistent backward tracking" {
  let previous = textured_frame()
  let next = shifted_right_by(previous, 6)
  let previous_pyramid = @image.Pyramid::build(previous, 3).unwrap()
  let next_pyramid = @image.Pyramid::build(next, 3).unwrap()
  let seed = seed_at(32.0, 32.0)
  let forward = @klt.track_pyramidal(
    previous_pyramid,
    next_pyramid,
    seed,
    solver_config(),
  )
  let inconsistent = @image.Pyramid::build(previous, 3).unwrap()
  let validated = validate_forward_backward(
    previous_pyramid,
    inconsistent,
    seed,
    forward,
    solver_config(),
  )
  assert_eq(validated.status, @klt.Rejected)
  assert_true(validated.forward_backward_error > 1.0)
}
