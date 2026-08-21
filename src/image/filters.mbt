///|
/// A finite convolution kernel in row-major order.
pub(all) struct Kernel {
  width : Int
  height : Int
  values : Array[Double]
  divisor : Double
} derive(Debug)

///|
pub(all) enum FilterError {
  InvalidKernel
  InvalidDivisor
  NonFiniteKernel
  EmptyFrame
} derive(Debug, Eq)

///|
pub fn Kernel::new(
  width : Int,
  height : Int,
  values : Array[Double],
  divisor : Double,
) -> Result[Kernel, FilterError] {
  if width <= 0 ||
    height <= 0 ||
    width % 2 == 0 ||
    height % 2 == 0 ||
    values.length() != width * height {
    return Err(InvalidKernel)
  }
  if !finite(divisor) || divisor == 0.0 {
    return Err(InvalidDivisor)
  }
  for value in values {
    if !finite(value) {
      return Err(NonFiniteKernel)
    }
  }
  Ok({ width, height, values: values.copy(), divisor })
}

///|
pub fn Kernel::box_blur(size : Int) -> Result[Kernel, FilterError] {
  if size < 1 || size % 2 == 0 {
    return Err(InvalidKernel)
  }
  let values : Array[Double] = []
  for _ in 0..<(size * size) {
    values.push(1.0)
  }
  Kernel::new(size, size, values, (size * size).to_double())
}

///|
pub fn Kernel::gaussian_3x3() -> Kernel {
  Kernel::new(3, 3, [1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0], 16.0).unwrap()
}

///|
pub fn Kernel::sobel_x() -> Kernel {
  Kernel::new(3, 3, [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0], 1.0).unwrap()
}

///|
pub fn Kernel::sobel_y() -> Kernel {
  Kernel::new(3, 3, [-1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0], 1.0).unwrap()
}

///|
pub fn GrayFrame::convolve(
  self : GrayFrame,
  kernel : Kernel,
  policy : BorderPolicy,
) -> Result[GrayFrame, FilterError] {
  if self.width <= 0 || self.height <= 0 {
    return Err(EmptyFrame)
  }
  let values : Array[Byte] = []
  let half_width = kernel.width / 2
  let half_height = kernel.height / 2
  for y in 0..<self.height {
    for x in 0..<self.width {
      let mut total = 0.0
      for ky in 0..<kernel.height {
        for kx in 0..<kernel.width {
          let point : @math.Vec2 = {
            x: (x + kx - half_width).to_double(),
            y: (y + ky - half_height).to_double(),
          }
          let sample = match self.sample(point, policy) {
            Some(value) => value
            None => 0.0
          }
          total += sample * kernel.values[ky * kernel.width + kx]
        }
      }
      let normalized = (total / kernel.divisor).max(0.0).min(255.0)
      values.push(normalized.to_int().to_byte())
    }
  }
  match GrayFrame::new(self.width, self.height, values) {
    Ok(frame) => Ok(frame)
    Err(_) => Err(EmptyFrame)
  }
}

///|
pub fn gradient_magnitude(
  frame : GrayFrame,
  policy : BorderPolicy,
) -> Result[GrayFrame, FilterError] {
  let horizontal = frame.convolve(Kernel::sobel_x(), policy)
  let vertical = frame.convolve(Kernel::sobel_y(), policy)
  match (horizontal, vertical) {
    (Ok(left), Ok(right)) => {
      let values : Array[Byte] = []
      for index in 0..<left.pixels.length() {
        let x = left.pixels[index].to_double()
        let y = right.pixels[index].to_double()
        values.push((x * x + y * y).sqrt().min(255.0).to_int().to_byte())
      }
      match GrayFrame::new(left.width, left.height, values) {
        Ok(frame) => Ok(frame)
        Err(_) => Err(EmptyFrame)
      }
    }
    (_, _) => Err(EmptyFrame)
  }
}

///|
pub fn threshold(
  frame : GrayFrame,
  cutoff : Double,
) -> Result[GrayFrame, FilterError] {
  if !finite(cutoff) {
    return Err(InvalidDivisor)
  }
  let values : Array[Byte] = []
  for pixel in frame.pixels {
    values.push(if pixel.to_double() >= cutoff { 255 } else { 0 })
  }
  match GrayFrame::new(frame.width, frame.height, values) {
    Ok(result) => Ok(result)
    Err(_) => Err(EmptyFrame)
  }
}

///|
pub fn erode(
  frame : GrayFrame,
  radius : Int,
  policy : BorderPolicy,
) -> Result[GrayFrame, FilterError] {
  if radius < 0 {
    return Err(InvalidKernel)
  }
  let values : Array[Byte] = []
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      let mut minimum = 255.0
      for dy in -radius..<(radius + 1) {
        for dx in -radius..<(radius + 1) {
          match
            frame.sample(
              { x: (x + dx).to_double(), y: (y + dy).to_double() },
              policy,
            ) {
            Some(value) => if value < minimum { minimum = value }
            None => ()
          }
        }
      }
      values.push(minimum.to_int().to_byte())
    }
  }
  match GrayFrame::new(frame.width, frame.height, values) {
    Ok(result) => Ok(result)
    Err(_) => Err(EmptyFrame)
  }
}

///|
pub fn dilate(
  frame : GrayFrame,
  radius : Int,
  policy : BorderPolicy,
) -> Result[GrayFrame, FilterError] {
  if radius < 0 {
    return Err(InvalidKernel)
  }
  let values : Array[Byte] = []
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      let mut maximum = 0.0
      for dy in -radius..<(radius + 1) {
        for dx in -radius..<(radius + 1) {
          match
            frame.sample(
              { x: (x + dx).to_double(), y: (y + dy).to_double() },
              policy,
            ) {
            Some(value) => if value > maximum { maximum = value }
            None => ()
          }
        }
      }
      values.push(maximum.to_int().to_byte())
    }
  }
  match GrayFrame::new(frame.width, frame.height, values) {
    Ok(result) => Ok(result)
    Err(_) => Err(EmptyFrame)
  }
}
