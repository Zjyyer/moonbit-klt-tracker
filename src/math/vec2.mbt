///|
/// A two-dimensional coordinate or displacement in pixel space.
pub(all) struct Vec2 {
  x : Double
  y : Double
} derive(Debug)

///|
/// Adds two coordinates component-wise.
pub fn Vec2::add(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
/// Multiplies both coordinate components by `factor`.
pub fn Vec2::scale(self : Vec2, factor : Double) -> Vec2 {
  { x: self.x * factor, y: self.y * factor }
}
