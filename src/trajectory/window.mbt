///|
/// A frame-indexed window of trajectory points.
pub(all) struct TrajectoryWindow {
  id : Int
  first_frame : Int
  last_frame : Int
  points : Array[TrajectoryPoint]
  coverage : Double
  continuity : Double
} derive(Debug)

///|
pub fn Trajectory::window(
  self : Trajectory,
  first : Int,
  last : Int,
) -> Result[TrajectoryWindow, TrajectoryError] {
  if first > last {
    return Err(InvalidInterval)
  }
  let points : Array[TrajectoryPoint] = []
  for point in self.points {
    if point.frame >= first && point.frame <= last {
      points.push(point)
    }
  }
  if points.length() == 0 {
    return Err(EmptyTrajectory)
  }
  let length = (last - first + 1).max(1)
  Ok({
    id: self.id,
    first_frame: first,
    last_frame: last,
    points,
    coverage: points.length().to_double() / length.to_double(),
    continuity: continuity(points, length),
  })
}

///|
fn continuity(points : Array[TrajectoryPoint], expected_length : Int) -> Double {
  if points.length() < 2 {
    return if expected_length <= 1 { 1.0 } else { 0.0 }
  }
  let mut consecutive = 0
  for index in 1..<points.length() {
    if points[index].frame - points[index - 1].frame == 1 {
      consecutive += 1
    }
  }
  consecutive.to_double() / (expected_length - 1).max(1).to_double()
}

///|
/// Keeps every nth point while preserving both endpoints.
pub fn Trajectory::downsample(
  self : Trajectory,
  step : Int,
) -> Result[Trajectory, TrajectoryError] {
  if step < 1 {
    return Err(InvalidInterval)
  }
  let points : Array[TrajectoryPoint] = []
  for index, point in self.points {
    if index % step == 0 || index == self.points.length() - 1 {
      points.push(point)
    }
  }
  Trajectory::new(self.id, points)
}

///|
/// Returns the point nearest to a coordinate, with deterministic ID-independent ties.
pub fn Trajectory::nearest(
  self : Trajectory,
  position : @math.Vec2,
) -> TrajectoryPoint {
  let mut best = self.points[0]
  let mut best_distance = distance(best.position, position)
  for point in self.points[1:] {
    let current_distance = distance(point.position, position)
    if current_distance < best_distance ||
      (current_distance == best_distance && point.frame < best.frame) {
      best = point
      best_distance = current_distance
    }
  }
  best
}

///|
pub(all) struct CoordinateSummary {
  minimum : @math.Vec2
  maximum : @math.Vec2
  center : @math.Vec2
  radius : Double
  area : Double
} derive(Debug)

///|
pub fn Trajectory::coordinate_summary(self : Trajectory) -> CoordinateSummary {
  let first = self.points[0].position
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y
  for point in self.points {
    min_x = min_x.min(point.position.x)
    min_y = min_y.min(point.position.y)
    max_x = max_x.max(point.position.x)
    max_y = max_y.max(point.position.y)
  }
  let center : @math.Vec2 = {
    x: (min_x + max_x) / 2.0,
    y: (min_y + max_y) / 2.0,
  }
  let mut radius = 0.0
  for point in self.points {
    radius = radius.max(distance(point.position, center))
  }
  {
    minimum: { x: min_x, y: min_y },
    maximum: { x: max_x, y: max_y },
    center,
    radius,
    area: (max_x - min_x) * (max_y - min_y),
  }
}

///|
pub fn Trajectory::weighted_centroid(self : Trajectory) -> @math.Vec2 {
  let mut total_weight = 0.0
  let mut x = 0.0
  let mut y = 0.0
  for point in self.points {
    let weight = point.confidence.max(0.000001)
    total_weight += weight
    x += point.position.x * weight
    y += point.position.y * weight
  }
  { x: x / total_weight, y: y / total_weight }
}

///|
pub fn Trajectory::displacement_between(
  self : Trajectory,
  first : Int,
  last : Int,
) -> Result[Double, TrajectoryError] {
  match self.window(first, last) {
    Err(error) => Err(error)
    Ok(window) => {
      if window.points.length() < 2 {
        return Err(EmptyTrajectory)
      }
      Ok(
        distance(
          window.points[0].position,
          window.points[window.points.length() - 1].position,
        ),
      )
    }
  }
}

///|
pub fn Trajectory::integrated_speed(self : Trajectory) -> Double {
  let mut total = 0.0
  for index in 1..<self.points.length() {
    let delta = self.points[index].frame - self.points[index - 1].frame
    total += distance(
        self.points[index].position,
        self.points[index - 1].position,
      ) /
      delta.to_double()
  }
  total
}

///|
pub fn Trajectory::jerk(self : Trajectory) -> Double {
  if self.points.length() < 4 {
    return 0.0
  }
  let mut previous_acceleration = 0.0
  let mut maximum = 0.0
  for index in 2..<self.points.length() {
    let first = self.points[index - 1]
    let second = self.points[index]
    let before = self.points[index - 2]
    let first_speed = distance(first.position, before.position) /
      (first.frame - before.frame).to_double()
    let second_speed = distance(second.position, first.position) /
      (second.frame - first.frame).to_double()
    let acceleration = second_speed - first_speed
    let jerk = abs(acceleration - previous_acceleration)
    maximum = maximum.max(jerk)
    previous_acceleration = acceleration
  }
  maximum
}
