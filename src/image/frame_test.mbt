///|
test "GrayFrame rejects pixels whose length differs from its dimensions" {
  let pixels : Array[Byte] = [0, 1, 2]
  assert_true(GrayFrame::new(2, 2, pixels) is Err(_))
}

///|
test "GrayFrame bilinear sampling returns integer pixel values" {
  let pixels : Array[Byte] = [0, 10, 20, 30]
  let frame = match GrayFrame::new(2, 2, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let point : @math.Vec2 = { x: 1.0, y: 0.0 }
  assert_eq(frame.sample_bilinear(point), Some(10.0))
}

///|
test "GrayFrame bilinear sampling is absent outside frame bounds" {
  let pixels : Array[Byte] = [0, 10, 20, 30]
  let frame = match GrayFrame::new(2, 2, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let outside : @math.Vec2 = { x: -0.1, y: 0.0 }
  assert_eq(frame.sample_bilinear(outside), None)
}
