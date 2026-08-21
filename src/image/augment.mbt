///|
/// Pixel-wise frame operations used by reproducible tracking fixtures.
pub fn GrayFrame::invert(self : GrayFrame) -> GrayFrame {
  let pixels : Array[Byte] = []
  for pixel in self.pixels {
    pixels.push((255 - pixel.to_int()).to_byte())
  }
  { width: self.width, height: self.height, pixels }
}

///|
pub fn GrayFrame::add_bias(self : GrayFrame, bias : Int) -> GrayFrame {
  let pixels : Array[Byte] = []
  for pixel in self.pixels {
    pixels.push((pixel.to_int() + bias).max(0).min(255).to_byte())
  }
  { width: self.width, height: self.height, pixels }
}

///|
pub fn GrayFrame::blend(
  self : GrayFrame,
  other : GrayFrame,
  alpha : Double,
) -> Result[GrayFrame, FrameError] {
  if self.width != other.width || self.height != other.height || !finite(alpha) {
    return Err(InvalidDimensions)
  }
  let ratio = alpha.max(0.0).min(1.0)
  let pixels : Array[Byte] = []
  for index in 0..<self.pixels.length() {
    let value = self.pixels[index].to_double() * (1.0 - ratio) +
      other.pixels[index].to_double() * ratio
    pixels.push(value.to_int().to_byte())
  }
  GrayFrame::new(self.width, self.height, pixels)
}

///|
pub fn GrayFrame::difference(
  self : GrayFrame,
  other : GrayFrame,
) -> Result[GrayFrame, FrameError] {
  if self.width != other.width || self.height != other.height {
    return Err(InvalidDimensions)
  }
  let pixels : Array[Byte] = []
  for index in 0..<self.pixels.length() {
    let value = (self.pixels[index].to_int() - other.pixels[index].to_int()).abs()
    pixels.push(value.to_byte())
  }
  GrayFrame::new(self.width, self.height, pixels)
}

///|
pub fn GrayFrame::crop(
  self : GrayFrame,
  left : Int,
  top : Int,
  width : Int,
  height : Int,
) -> Result[GrayFrame, FrameError] {
  if left < 0 ||
    top < 0 ||
    width <= 0 ||
    height <= 0 ||
    left + width > self.width ||
    top + height > self.height {
    return Err(InvalidDimensions)
  }
  let pixels : Array[Byte] = []
  for y in top..<(top + height) {
    for x in left..<(left + width) {
      pixels.push(self.pixels[y * self.width + x])
    }
  }
  GrayFrame::new(width, height, pixels)
}

///|
pub fn GrayFrame::histogram(self : GrayFrame) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<256 {
    result.push(0)
  }
  for pixel in self.pixels {
    result[pixel.to_int()] += 1
  }
  result
}

///|
pub fn GrayFrame::mean_intensity(self : GrayFrame) -> Double {
  let mut total = 0.0
  for pixel in self.pixels {
    total += pixel.to_double()
  }
  total / self.pixels.length().to_double()
}

///|
pub fn GrayFrame::contrast(self : GrayFrame) -> Double {
  let mean = self.mean_intensity()
  let mut total = 0.0
  for pixel in self.pixels {
    let delta = pixel.to_double() - mean
    total += delta * delta
  }
  (total / self.pixels.length().to_double()).sqrt()
}
