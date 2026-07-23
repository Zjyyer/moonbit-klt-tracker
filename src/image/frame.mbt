///|
/// A grayscale frame's dimensions or pixel storage is invalid.
pub(all) enum FrameError {
  InvalidDimensions
  InvalidPixelLength(expected~ : Int, actual~ : Int)
} derive(Debug, Eq)

///|
/// A validated row-major grayscale image with one byte per pixel.
pub(all) struct GrayFrame {
  width : Int
  height : Int
  pixels : Array[Byte]
} derive(Debug)

///|
/// The largest representable positive `Int` on supported MoonBit targets.
const MAX_INT : Int = 2147483647

///|
/// Constructs a frame when its dimensions and pixel count agree.
pub fn GrayFrame::new(
  width : Int,
  height : Int,
  pixels : Array[Byte],
) -> Result[GrayFrame, FrameError] {
  if width <= 0 || height <= 0 {
    Err(InvalidDimensions)
  } else if width > MAX_INT / height {
    Err(InvalidDimensions)
  } else {
    let expected = width * height
    if pixels.length() != expected {
      Err(InvalidPixelLength(expected~, actual=pixels.length()))
    } else {
      Ok({ width, height, pixels })
    }
  }
}

///|
/// Samples within the inclusive pixel domain using bilinear interpolation.
pub fn GrayFrame::sample_bilinear(
  self : GrayFrame,
  point : @math.Vec2,
) -> Double? {
  let max_x = (self.width - 1).to_double()
  let max_y = (self.height - 1).to_double()
  if point.x.is_nan() ||
    point.y.is_nan() ||
    point.x < 0.0 ||
    point.y < 0.0 ||
    point.x > max_x ||
    point.y > max_y {
    None
  } else {
    let left = point.x.floor().to_int()
    let top = point.y.floor().to_int()
    let right = (left + 1).min(self.width - 1)
    let bottom = (top + 1).min(self.height - 1)
    let horizontal = point.x - left.to_double()
    let vertical = point.y - top.to_double()
    let top_left = self.pixels[top * self.width + left].to_double()
    let top_right = self.pixels[top * self.width + right].to_double()
    let bottom_left = self.pixels[bottom * self.width + left].to_double()
    let bottom_right = self.pixels[bottom * self.width + right].to_double()
    let top_value = top_left * (1.0 - horizontal) + top_right * horizontal
    let bottom_value = bottom_left * (1.0 - horizontal) +
      bottom_right * horizontal
    Some(top_value * (1.0 - vertical) + bottom_value * vertical)
  }
}
