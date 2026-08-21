///|
/// Smooths positions with a centered confidence-weighted moving average.
pub fn Trajectory::smooth(
  self : Trajectory,
  window : Int,
) -> Result[Trajectory, TrajectoryError] {
  if window < 1 || window % 2 == 0 {
    return Err(InvalidWindow)
  }
  let radius = window / 2
  let result : Array[TrajectoryPoint] = []
  for index in 0..<self.points.length() {
    let begin = if index < radius { 0 } else { index - radius }
    let end = if index + radius + 1 > self.points.length() {
      self.points.length()
    } else {
      index + radius + 1
    }
    let mut weight = 0.0
    let mut x = 0.0
    let mut y = 0.0
    for neighbor in begin..<end {
      let confidence = self.points[neighbor].confidence
      let safe_weight = if confidence <= 0.0 { 0.000001 } else { confidence }
      weight += safe_weight
      x += self.points[neighbor].position.x * safe_weight
      y += self.points[neighbor].position.y * safe_weight
    }
    let original = self.points[index]
    result.push({
      frame: original.frame,
      position: { x: x / weight, y: y / weight },
      confidence: original.confidence,
      state: original.state,
    })
  }
  Ok({ id: self.id, points: result })
}

///|
/// Removes points whose local speed exceeds a finite threshold.
pub fn Trajectory::reject_speed(
  self : Trajectory,
  maximum : Double,
) -> Result[Trajectory, TrajectoryError] {
  if maximum < 0.0 || !finite(maximum) {
    return Err(InvalidWindow)
  }
  let result : Array[TrajectoryPoint] = []
  for index, point in self.points {
    if index == 0 {
      result.push(point)
    } else {
      let previous = self.points[index - 1]
      let delta = point.frame - previous.frame
      let speed = distance(point.position, previous.position) /
        delta.to_double()
      if speed <= maximum {
        result.push(point)
      }
    }
  }
  if result.length() == 0 {
    Err(EmptyTrajectory)
  } else {
    Trajectory::new(self.id, result)
  }
}
