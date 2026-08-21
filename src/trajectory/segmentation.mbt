///|
/// Segmentation controls for long-running tracks.
pub(all) struct SegmentationConfig {
  maximum_gap : Int
  minimum_length : Int
  maximum_turn : Double
} derive(Debug)

///|
pub fn SegmentationConfig::new(
  maximum_gap : Int,
  minimum_length : Int,
  maximum_turn : Double,
) -> Result[SegmentationConfig, TrajectoryError] {
  if maximum_gap < 0 ||
    minimum_length < 1 ||
    maximum_turn < 0.0 ||
    !finite(maximum_turn) {
    Err(InvalidWindow)
  } else {
    Ok({ maximum_gap, minimum_length, maximum_turn })
  }
}

///|
pub fn Trajectory::segment(
  self : Trajectory,
  config : SegmentationConfig,
) -> Array[Trajectory] {
  let result : Array[Trajectory] = []
  let current : Array[TrajectoryPoint] = []
  for index, point in self.points {
    if index > 0 {
      let previous = self.points[index - 1]
      let gap = point.frame - previous.frame - 1
      if gap > config.maximum_gap ||
        turn_angle(self.points, index) > config.maximum_turn {
        if current.length() >= config.minimum_length {
          result.push(Trajectory::new(self.id, current.copy()).unwrap())
        }
        current.clear()
      }
    }
    current.push(point)
  }
  if current.length() >= config.minimum_length {
    result.push(Trajectory::new(self.id, current).unwrap())
  }
  result
}

///|
fn turn_angle(points : Array[TrajectoryPoint], index : Int) -> Double {
  if index < 2 {
    return 0.0
  }
  let before = points[index - 2]
  let middle = points[index - 1]
  let after = points[index]
  let first_x = middle.position.x - before.position.x
  let first_y = middle.position.y - before.position.y
  let second_x = after.position.x - middle.position.x
  let second_y = after.position.y - middle.position.y
  let first_length = (first_x * first_x + first_y * first_y).sqrt()
  let second_length = (second_x * second_x + second_y * second_y).sqrt()
  if first_length == 0.0 || second_length == 0.0 {
    0.0
  } else {
    let cosine = ((first_x * second_x + first_y * second_y) /
      (first_length * second_length))
      .max(-1.0)
      .min(1.0)
    1.0 - cosine
  }
}

///|
pub fn merge_segments(
  segments : Array[Trajectory],
) -> Result[Trajectory, TrajectoryError] {
  if segments.length() == 0 {
    return Err(EmptyTrajectory)
  }
  let id = segments[0].id
  let points : Array[TrajectoryPoint] = []
  for segment in segments {
    if segment.id != id {
      return Err(InvalidId)
    }
    for point in segment.points {
      points.push(point)
    }
  }
  Trajectory::new(id, points)
}

///|
pub fn overlap(left : Trajectory, right : Trajectory) -> Double {
  let first = left.first_frame().unwrap().max(right.first_frame().unwrap())
  let last = left.last_frame().unwrap().min(right.last_frame().unwrap())
  if first > last {
    0.0
  } else {
    (last - first + 1).to_double() /
    (left.duration().min(right.duration()) + 1).to_double()
  }
}
