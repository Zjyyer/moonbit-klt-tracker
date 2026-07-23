///|
/// Per-pixel horizontal and vertical image derivatives.
pub(all) struct GradientFrame {
  width : Int
  height : Int
  gradients : Array[@math.Vec2]
} derive(Debug)

///|
/// Computes central-difference derivatives with reflected image edges.
pub fn GradientFrame::from_frame(frame : GrayFrame) -> GradientFrame {
  let gradients = []
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      let left = frame.pixel_at_reflected(x - 1, y).to_double()
      let right = frame.pixel_at_reflected(x + 1, y).to_double()
      let top = frame.pixel_at_reflected(x, y - 1).to_double()
      let bottom = frame.pixel_at_reflected(x, y + 1).to_double()
      gradients.push(@math.Vec2::{
        x: (right - left) / 2.0,
        y: (bottom - top) / 2.0,
      })
    }
  }
  { width: frame.width, height: frame.height, gradients }
}

///|
/// Bilinearly samples a derivative within the inclusive pixel domain.
pub fn GradientFrame::at(
  self : GradientFrame,
  point : @math.Vec2,
) -> @math.Vec2? {
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
    let top_left = self.gradients[top * self.width + left]
    let top_right = self.gradients[top * self.width + right]
    let bottom_left = self.gradients[bottom * self.width + left]
    let bottom_right = self.gradients[bottom * self.width + right]
    let top_value = @math.Vec2::{
      x: top_left.x * (1.0 - horizontal) + top_right.x * horizontal,
      y: top_left.y * (1.0 - horizontal) + top_right.y * horizontal,
    }
    let bottom_value = @math.Vec2::{
      x: bottom_left.x * (1.0 - horizontal) + bottom_right.x * horizontal,
      y: bottom_left.y * (1.0 - horizontal) + bottom_right.y * horizontal,
    }
    Some(@math.Vec2::{
      x: top_value.x * (1.0 - vertical) + bottom_value.x * vertical,
      y: top_value.y * (1.0 - vertical) + bottom_value.y * vertical,
    })
  }
}
