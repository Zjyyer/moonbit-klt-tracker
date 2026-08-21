///|
/// Inserts linearly interpolated samples at each missing integer frame.
pub fn Trajectory::resample(
  self : Trajectory,
  interval : Int,
) -> Result[Trajectory, TrajectoryError] {
  if interval < 1 {
    return Err(InvalidInterval)
  }
  let result : Array[TrajectoryPoint] = []
  for index in 0..<self.points.length() {
    let current = self.points[index]
    result.push(current)
    if index + 1 < self.points.length() {
      let next = self.points[index + 1]
      let gap = next.frame - current.frame
      if gap > interval {
        let mut frame = current.frame + interval
        while frame < next.frame {
          let ratio = (frame - current.frame).to_double() / gap.to_double()
          result.push({
            frame,
            position: {
              x: current.position.x +
              (next.position.x - current.position.x) * ratio,
              y: current.position.y +
              (next.position.y - current.position.y) * ratio,
            },
            confidence: current.confidence +
            (next.confidence - current.confidence) * ratio,
            state: if current.state == Accepted && next.state == Accepted {
              Accepted
            } else {
              Lost
            },
          })
          frame += interval
        }
      }
    }
  }
  Trajectory::new(self.id, result)
}

///|
/// Returns the point at a frame, or the nearest endpoint when outside the range.
pub fn Trajectory::sample_at(self : Trajectory, frame : Int) -> TrajectoryPoint {
  if frame <= self.points[0].frame {
    return self.points[0]
  }
  if frame >= self.points[self.points.length() - 1].frame {
    return self.points[self.points.length() - 1]
  }
  for index in 1..<self.points.length() {
    if frame <= self.points[index].frame {
      let previous = self.points[index - 1]
      let current = self.points[index]
      let ratio = (frame - previous.frame).to_double() /
        (current.frame - previous.frame).to_double()
      return {
        frame,
        position: {
          x: previous.position.x +
          (current.position.x - previous.position.x) * ratio,
          y: previous.position.y +
          (current.position.y - previous.position.y) * ratio,
        },
        confidence: previous.confidence +
        (current.confidence - previous.confidence) * ratio,
        state: if previous.state == Accepted && current.state == Accepted {
          Accepted
        } else {
          Lost
        },
      }
    }
  }
  self.points[self.points.length() - 1]
}

///|
/// Returns a frame-bounded view of a trajectory.
pub fn Trajectory::slice(
  self : Trajectory,
  first : Int,
  last : Int,
) -> Result[Trajectory, TrajectoryError] {
  if first > last {
    return Err(InvalidInterval)
  }
  let result : Array[TrajectoryPoint] = []
  for point in self.points {
    if point.frame >= first && point.frame <= last {
      result.push(point)
    }
  }
  if result.length() == 0 {
    Err(EmptyTrajectory)
  } else {
    Trajectory::new(self.id, result)
  }
}
