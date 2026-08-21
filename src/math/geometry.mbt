///|
/// Small geometry helpers for image-space diagnostics.
pub(all) struct Segment2 {
  start : Vec2
  end : Vec2
} derive(Debug)

///|
pub fn Segment2::length(self : Segment2) -> Double {
  distance(self.start, self.end)
}

///|
pub fn Segment2::midpoint(self : Segment2) -> Vec2 {
  { x: (self.start.x + self.end.x) / 2.0, y: (self.start.y + self.end.y) / 2.0 }
}

///|
pub fn Segment2::direction(self : Segment2) -> Vec2 {
  let length = self.length()
  if length == 0.0 {
    { x: 0.0, y: 0.0 }
  } else {
    {
      x: (self.end.x - self.start.x) / length,
      y: (self.end.y - self.start.y) / length,
    }
  }
}

///|
pub fn Segment2::project(self : Segment2, point : Vec2) -> Vec2 {
  let direction = self.direction()
  let relative = { x: point.x - self.start.x, y: point.y - self.start.y }
  let parameter = dot(relative, direction).max(0.0).min(self.length())
  self.start.add(direction.scale(parameter))
}

///|
pub fn Segment2::distance_to(self : Segment2, point : Vec2) -> Double {
  distance(self.project(point), point)
}

///|
pub fn rectangle_contains(minimum : Vec2, maximum : Vec2, point : Vec2) -> Bool {
  point.x >= minimum.x &&
  point.x <= maximum.x &&
  point.y >= minimum.y &&
  point.y <= maximum.y
}

///|
pub fn rectangle_area(minimum : Vec2, maximum : Vec2) -> Double {
  (maximum.x - minimum.x).max(0.0) * (maximum.y - minimum.y).max(0.0)
}

///|
pub fn rectangle_intersection(
  left_minimum : Vec2,
  left_maximum : Vec2,
  right_minimum : Vec2,
  right_maximum : Vec2,
) -> Double {
  let minimum = {
    x: left_minimum.x.max(right_minimum.x),
    y: left_minimum.y.max(right_minimum.y),
  }
  let maximum = {
    x: left_maximum.x.min(right_maximum.x),
    y: left_maximum.y.min(right_maximum.y),
  }
  rectangle_area(minimum, maximum)
}

///|
pub fn angle_between(left : Vec2, right : Vec2) -> Double {
  let left_length = norm(left)
  let right_length = norm(right)
  if left_length == 0.0 || right_length == 0.0 {
    0.0
  } else {
    1.0 - (dot(left, right) / (left_length * right_length)).max(-1.0).min(1.0)
  }
}

///|
pub fn norm(value : Vec2) -> Double {
  (value.x * value.x + value.y * value.y).sqrt()
}

///|
pub fn dot(left : Vec2, right : Vec2) -> Double {
  left.x * right.x + left.y * right.y
}

///|
pub fn distance(left : Vec2, right : Vec2) -> Double {
  let dx = left.x - right.x
  let dy = left.y - right.y
  (dx * dx + dy * dy).sqrt()
}

///|
pub fn cross(left : Vec2, right : Vec2) -> Double {
  left.x * right.y - left.y * right.x
}

///|
pub fn polygon_area(points : Array[Vec2]) -> Double {
  if points.length() < 3 {
    return 0.0
  }
  let mut area = 0.0
  for index in 0..<points.length() {
    let next = (index + 1) % points.length()
    area += points[index].x * points[next].y - points[next].x * points[index].y
  }
  let absolute = if area < 0.0 { -area } else { area }
  absolute / 2.0
}

///|
pub fn centroid(points : Array[Vec2]) -> Vec2 {
  if points.length() == 0 {
    return { x: 0.0, y: 0.0 }
  }
  let mut x = 0.0
  let mut y = 0.0
  for point in points {
    x += point.x
    y += point.y
  }
  { x: x / points.length().to_double(), y: y / points.length().to_double() }
}
