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

///|
test "Shi-Tomasi rejects infinite score and suppression configuration" {
  let frame = corner_frame()
  let infinity = 1.0 / 0.0
  let positive_infinite_score : FeatureConfig = {
    window_size: 3,
    minimum_score: infinity,
    max_features: 2,
    suppression_radius: 1.0,
  }
  let negative_infinite_score : FeatureConfig = {
    window_size: 3,
    minimum_score: -infinity,
    max_features: 2,
    suppression_radius: 1.0,
  }
  let positive_infinite_radius : FeatureConfig = {
    window_size: 3,
    minimum_score: 1.0,
    max_features: 2,
    suppression_radius: infinity,
  }
  let negative_infinite_radius : FeatureConfig = {
    window_size: 3,
    minimum_score: 1.0,
    max_features: 2,
    suppression_radius: -infinity,
  }
  assert_true(
    detect_shi_tomasi(frame, positive_infinite_score)
    is Err(InvalidMinimumScore),
  )
  assert_true(
    detect_shi_tomasi(frame, negative_infinite_score)
    is Err(InvalidMinimumScore),
  )
  assert_true(
    detect_shi_tomasi(frame, positive_infinite_radius)
    is Err(InvalidSuppressionRadius),
  )
  assert_true(
    detect_shi_tomasi(frame, negative_infinite_radius)
    is Err(InvalidSuppressionRadius),
  )
}

///|
fn two_blob_frame() -> @image.GrayFrame {
  let pixels : Array[Byte] = []
  for y in 0..<11 {
    for x in 0..<11 {
      let inside_first = x >= 2 && x <= 3 && y >= 2 && y <= 3
      let inside_second = x >= 7 && x <= 8 && y >= 7 && y <= 8
      pixels.push(if inside_first || inside_second { 255 } else { 0 })
    }
  }
  frame_or_fail(11, 11, pixels)
}

///|
test "detector orders tied blob scores by y then x and applies radius NMS" {
  let config : FeatureConfig = {
    window_size: 3,
    minimum_score: 1.0,
    max_features: 2,
    suppression_radius: 3.0,
  }
  let selected = match detect_shi_tomasi(two_blob_frame(), config) {
    Ok(seeds) => seeds
    Err(_) => fail("expected detector configuration to be valid")
  }
  assert_eq(selected.length(), 2)
  assert_eq(selected[0].position.x, 2.0)
  assert_eq(selected[0].position.y, 2.0)
  assert_eq(selected[1].position.x, 7.0)
  assert_eq(selected[1].position.y, 7.0)
  assert_eq(selected[0].score, selected[1].score)
}
