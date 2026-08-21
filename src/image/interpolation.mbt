///|
/// Border behavior for patch and image sampling.
pub(all) enum BorderPolicy {
  Reject
  Clamp
  Reflect
  Wrap
} derive(Debug, Eq)

///|
/// Samples a frame with an explicit border policy.
pub fn GrayFrame::sample(
  self : GrayFrame,
  point : @math.Vec2,
  policy : BorderPolicy,
) -> Double? {
  let x = normalize_coordinate(point.x, (self.width - 1).to_double(), policy)
  let y = normalize_coordinate(point.y, (self.height - 1).to_double(), policy)
  match (x, y) {
    (Some(safe_x), Some(safe_y)) =>
      self.sample_bilinear({ x: safe_x, y: safe_y })
    (_, _) => None
  }
}

///|
fn normalize_coordinate(
  value : Double,
  maximum : Double,
  policy : BorderPolicy,
) -> Double? {
  if value.is_nan() || value.is_inf() {
    return None
  }
  match policy {
    Reject => if value < 0.0 || value > maximum { None } else { Some(value) }
    Clamp => Some(value.max(0.0).min(maximum))
    Reflect => Some(reflect(value, maximum))
    Wrap => Some(wrap(value, maximum + 1.0))
  }
}

///|
fn reflect(value : Double, maximum : Double) -> Double {
  if maximum == 0.0 {
    return 0.0
  }
  let period = maximum * 2.0
  let mut wrapped = value % period
  if wrapped < 0.0 {
    wrapped += period
  }
  if wrapped > maximum {
    period - wrapped
  } else {
    wrapped
  }
}

///|
fn wrap(value : Double, period : Double) -> Double {
  let mut wrapped = value % period
  if wrapped < 0.0 {
    wrapped += period
  }
  wrapped
}

///|
/// A regularly sampled rectangular window around a floating-point center.
pub(all) struct Patch {
  width : Int
  height : Int
  center : @math.Vec2
  values : Array[Double]
} derive(Debug)

///|
/// Extracts a patch using the selected border behavior.
pub fn extract_patch(
  frame : GrayFrame,
  center : @math.Vec2,
  width : Int,
  height : Int,
  policy : BorderPolicy,
) -> Result[Patch, FrameError] {
  if width <= 0 || height <= 0 {
    return Err(InvalidDimensions)
  }
  let values : Array[Double] = []
  let half_width = (width - 1).to_double() / 2.0
  let half_height = (height - 1).to_double() / 2.0
  for y in 0..<height {
    for x in 0..<width {
      let point : @math.Vec2 = {
        x: center.x - half_width + x.to_double(),
        y: center.y - half_height + y.to_double(),
      }
      match frame.sample(point, policy) {
        Some(value) => values.push(value)
        None => return Err(InvalidDimensions)
      }
    }
  }
  Ok({ width, height, center, values })
}

///|
pub fn Patch::at(self : Patch, x : Int, y : Int) -> Double? {
  if x < 0 || y < 0 || x >= self.width || y >= self.height {
    None
  } else {
    Some(self.values[y * self.width + x])
  }
}

///|
pub fn Patch::mean(self : Patch) -> Double {
  let mut total = 0.0
  for value in self.values {
    total += value
  }
  total / self.values.length().to_double()
}

///|
pub fn Patch::variance(self : Patch) -> Double {
  let mean = self.mean()
  let mut total = 0.0
  for value in self.values {
    let difference = value - mean
    total += difference * difference
  }
  total / self.values.length().to_double()
}
