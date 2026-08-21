///|
fn filter_frame() -> GrayFrame {
  GrayFrame::new(3, 3, [0, 10, 20, 30, 40, 50, 60, 70, 80]).unwrap()
}

///|
test "filters validate kernels and preserve frame dimensions" {
  let frame = filter_frame()
  let blurred = frame.convolve(Kernel::gaussian_3x3(), Clamp).unwrap()
  assert_eq(blurred.width, 3)
  assert_eq(blurred.height, 3)
  assert_true(
    Kernel::new(2, 2, [1.0, 1.0, 1.0, 1.0], 1.0) is Err(InvalidKernel),
  )
  assert_true(Kernel::box_blur(0) is Err(InvalidKernel))
}

///|
test "gradient threshold morphology and border policies are deterministic" {
  let frame = filter_frame()
  let gradient = gradient_magnitude(frame, Clamp).unwrap()
  assert_eq(gradient.pixels.length(), 9)
  let binary = threshold(frame, 40.0).unwrap()
  assert_eq(binary.pixels[0], 0)
  assert_eq(binary.pixels[8], 255)
  assert_eq(erode(binary, 0, Reject).unwrap().pixels, binary.pixels)
  assert_eq(dilate(binary, 0, Reject).unwrap().pixels, binary.pixels)
  assert_eq(frame.sample({ x: -1.0, y: 0.0 }, Clamp), Some(0.0))
}
