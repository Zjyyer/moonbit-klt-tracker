///|
fn frame_or_fail(
  width : Int,
  height : Int,
  pixels : Array[Byte],
) -> @image.GrayFrame {
  @image.GrayFrame::new(width, height, pixels).unwrap()
}

///|
fn corner_frame() -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<9 {
    for x in 0..<9 {
      pixels.push(if x >= 4 && y >= 4 { 255 } else { 0 })
    }
  }
  frame_or_fail(9, 9, pixels)
}

///|
fn detector_config(max_features : Int) -> FeatureConfig {
  { window_size: 3, minimum_score: 1.0, max_features, suppression_radius: 2.0 }
}

///|
test "Shi-Tomasi detector selects the synthetic corner" {
  let seeds = match detect_shi_tomasi(corner_frame(), detector_config(10)) {
    Ok(seeds) => seeds
    Err(_) => fail("expected detector configuration to be valid")
  }
  assert_true(seeds.length() > 0)
  assert_true(seeds[0].position.x >= 3.0 && seeds[0].position.x <= 5.0)
  assert_true(seeds[0].position.y >= 3.0 && seeds[0].position.y <= 5.0)
}

///|
test "Shi-Tomasi detector has no candidates for a flat frame" {
  let flat = frame_or_fail(9, 9, Array::make(81, 42))
  match detect_shi_tomasi(flat, detector_config(10)) {
    Ok(seeds) => assert_eq(seeds.length(), 0)
    Err(_) => fail("expected detector configuration to be valid")
  }
}

///|
test "Shi-Tomasi detector caps output at requested feature count" {
  let seeds = match detect_shi_tomasi(corner_frame(), detector_config(1)) {
    Ok(seeds) => seeds
    Err(_) => fail("expected detector configuration to be valid")
  }
  assert_eq(seeds.length(), 1)
}

///|
test "seed validation rejects a seed outside the usable frame window" {
  let frame = corner_frame()
  let outside : SeedPoint = {
    position: @math.Vec2::{ x: -0.1, y: 4.0 },
    score: 2.0,
  }
  assert_true(validate_seeds(frame, [outside]) is Err(_))
}
