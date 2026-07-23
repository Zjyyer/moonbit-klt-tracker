///|
test "GradientFrame reports central differences for a horizontal ramp" {
  let pixels : Array[Byte] = [
    0, 10, 20, 30, 40, 0, 10, 20, 30, 40, 0, 10, 20, 30, 40, 0, 10, 20, 30, 40, 0,
    10, 20, 30, 40,
  ]
  let frame = match GrayFrame::new(5, 5, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let gradient = GradientFrame::from_frame(frame)
  let point : @math.Vec2 = { x: 2.0, y: 2.0 }
  match gradient.at(point) {
    Some(value) => {
      assert_eq(value.x, 10.0)
      assert_eq(value.y, 0.0)
    }
    None => fail("expected an in-bounds gradient")
  }
}

///|
test "GradientFrame returns zero horizontal gradient for a one-pixel-wide frame" {
  let pixels : Array[Byte] = [0, 10, 20]
  let frame = match GrayFrame::new(1, 3, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let point : @math.Vec2 = { x: 0.0, y: 1.0 }
  match GradientFrame::from_frame(frame).at(point) {
    Some(value) => {
      assert_eq(value.x, 0.0)
      assert_eq(value.y, 10.0)
    }
    None => fail("expected an in-bounds gradient")
  }
}

///|
test "GradientFrame returns zero vertical gradient for a one-pixel-high frame" {
  let pixels : Array[Byte] = [0, 10, 20]
  let frame = match GrayFrame::new(3, 1, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let point : @math.Vec2 = { x: 1.0, y: 0.0 }
  match GradientFrame::from_frame(frame).at(point) {
    Some(value) => {
      assert_eq(value.x, 10.0)
      assert_eq(value.y, 0.0)
    }
    None => fail("expected an in-bounds gradient")
  }
}

///|
test "Pyramid builds two levels at half resolution" {
  let pixels : Array[Byte] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24,
  ]
  let frame = match GrayFrame::new(5, 5, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let pyramid = match Pyramid::build(frame, 2) {
    Ok(pyramid) => pyramid
    Err(_) => fail("expected a valid two-level pyramid")
  }
  let coarse = pyramid.level(1)
  assert_eq(coarse.width, 2)
  assert_eq(coarse.height, 2)
}

///|
test "Pyramid uses the reflected Gaussian kernel at image edges" {
  let pixels : Array[Byte] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24,
  ]
  let frame = match GrayFrame::new(5, 5, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  let pyramid = match Pyramid::build(frame, 2) {
    Ok(pyramid) => pyramid
    Err(_) => fail("expected a valid two-level pyramid")
  }
  assert_eq(pyramid.level(1).pixels[0], 4)
}

///|
test "Pyramid rejects a depth that reduces a 3 by 3 frame" {
  let pixels : Array[Byte] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
  let frame = match GrayFrame::new(3, 3, pixels) {
    Ok(frame) => frame
    Err(_) => fail("expected a valid frame")
  }
  assert_true(Pyramid::build(frame, 2) is Err(_))
}
