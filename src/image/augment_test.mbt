///|
test "frame augmentation is deterministic and dimension-safe" {
  let frame = GrayFrame::new(2, 2, [0, 10, 20, 255]).unwrap()
  assert_eq(frame.invert().pixels, [255, 245, 235, 0])
  assert_eq(frame.add_bias(-5).pixels, [0, 5, 15, 250])
  assert_eq(frame.crop(0, 0, 1, 2).unwrap().pixels, [0, 20])
  assert_eq(frame.histogram()[255], 1)
  assert_true(frame.contrast() > 100.0)
  assert_true(frame.crop(-1, 0, 1, 1) is Err(InvalidDimensions))
}
