///|
pub(all) enum PointState {
  Accepted
  Lost
  Rejected
} derive(Debug, Eq)

///|
pub(all) struct TrajectoryPoint {
  frame : Int
  position : @math.Vec2
  confidence : Double
  state : PointState
} derive(Debug)

///|
pub(all) struct Trajectory {
  id : Int
  points : Array[TrajectoryPoint]
} derive(Debug)

///|
pub(all) enum TrajectoryError {
  InvalidId
  EmptyTrajectory
  NonFinitePoint
  NonIncreasingFrames
  InvalidInterval
  InvalidWindow
} derive(Debug, Eq)

///|
pub fn Trajectory::new(
  id : Int,
  points : Array[TrajectoryPoint],
) -> Result[Trajectory, TrajectoryError] {
  if id < 0 {
    return Err(InvalidId)
  }
  if points.length() == 0 {
    return Err(EmptyTrajectory)
  }
  let ordered = points.copy()
  ordered.sort_by(fn(left, right) { left.frame.compare(right.frame) })
  match validate_points(ordered) {
    Ok(_) => Ok({ id, points: ordered })
    Err(error) => Err(error)
  }
}

///|
fn validate_points(
  points : Array[TrajectoryPoint],
) -> Result[Unit, TrajectoryError] {
  let mut previous : Int? = None
  for point in points {
    if !finite(point.position.x) ||
      !finite(point.position.y) ||
      !finite(point.confidence) ||
      point.confidence < 0.0 ||
      point.confidence > 1.0 {
      return Err(NonFinitePoint)
    }
    match previous {
      Some(frame) => if frame == point.frame { return Err(NonIncreasingFrames) }
      None => ()
    }
    previous = Some(point.frame)
  }
  Ok(())
}

///|
pub fn Trajectory::first_frame(self : Trajectory) -> Int? {
  if self.points.length() == 0 {
    None
  } else {
    Some(self.points[0].frame)
  }
}

///|
pub fn Trajectory::last_frame(self : Trajectory) -> Int? {
  if self.points.length() == 0 {
    None
  } else {
    Some(self.points[self.points.length() - 1].frame)
  }
}

///|
pub fn Trajectory::duration(self : Trajectory) -> Int {
  match self.first_frame() {
    Some(first) =>
      match self.last_frame() {
        Some(last) => last - first
        None => 0
      }
    None => 0
  }
}

///|
pub fn Trajectory::displacement(self : Trajectory) -> Double {
  if self.points.length() < 2 {
    return 0.0
  }
  distance(
    self.points[0].position,
    self.points[self.points.length() - 1].position,
  )
}

///|
pub fn Trajectory::path_length(self : Trajectory) -> Double {
  let mut total = 0.0
  for index in 1..<self.points.length() {
    total += distance(
      self.points[index - 1].position,
      self.points[index].position,
    )
  }
  total
}

///|
pub fn Trajectory::straightness(self : Trajectory) -> Double {
  let length = self.path_length()
  if length == 0.0 {
    1.0
  } else {
    self.displacement() / length
  }
}

///|
pub fn Trajectory::gap_count(self : Trajectory) -> Int {
  let mut gaps = 0
  for index in 1..<self.points.length() {
    let delta = self.points[index].frame - self.points[index - 1].frame
    if delta > 1 {
      gaps += delta - 1
    }
  }
  gaps
}

///|
pub fn Trajectory::speed(self : Trajectory) -> Double {
  if self.points.length() < 2 {
    return 0.0
  }
  let mut distance_sum = 0.0
  let mut frame_sum = 0
  for index in 1..<self.points.length() {
    distance_sum += distance(
      self.points[index - 1].position,
      self.points[index].position,
    )
    frame_sum += self.points[index].frame - self.points[index - 1].frame
  }
  if frame_sum == 0 {
    0.0
  } else {
    distance_sum / frame_sum.to_double()
  }
}

///|
pub fn Trajectory::acceleration(self : Trajectory) -> Double {
  if self.points.length() < 3 {
    return 0.0
  }
  let mut previous_speed = 0.0
  let mut maximum_change = 0.0
  for index in 1..<self.points.length() {
    let frame_delta = self.points[index].frame - self.points[index - 1].frame
    let current_speed = distance(
        self.points[index - 1].position,
        self.points[index].position,
      ) /
      frame_delta.to_double()
    let change = abs(current_speed - previous_speed) / frame_delta.to_double()
    if change > maximum_change {
      maximum_change = change
    }
    previous_speed = current_speed
  }
  maximum_change
}

///|
pub fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
pub fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
pub fn distance(left : @math.Vec2, right : @math.Vec2) -> Double {
  let dx = left.x - right.x
  let dy = left.y - right.y
  (dx * dx + dy * dy).sqrt()
}
