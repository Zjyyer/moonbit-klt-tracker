///|
/// A compact collection of motion descriptors for one trajectory.
pub(all) struct MotionMetrics {
  displacement : Double
  path_length : Double
  straightness : Double
  mean_speed : Double
  peak_speed : Double
  acceleration : Double
  heading_change : Double
  signed_area : Double
  duration : Int
  observed_frames : Int
} derive(Debug)

///|
pub fn Trajectory::metrics(self : Trajectory) -> MotionMetrics {
  let mut peak = 0.0
  let mut heading_change = 0.0
  let mut signed_area = 0.0
  let mut previous_heading : Double? = None
  for index in 1..<self.points.length() {
    let previous = self.points[index - 1]
    let current = self.points[index]
    let dx = current.position.x - previous.position.x
    let dy = current.position.y - previous.position.y
    let frame_delta = current.frame - previous.frame
    let speed = (dx * dx + dy * dy).sqrt() / frame_delta.to_double()
    if speed > peak {
      peak = speed
    }
    let heading = atan2(dy, dx)
    match previous_heading {
      Some(old) => heading_change += angle_distance(old, heading)
      None => ()
    }
    previous_heading = Some(heading)
    signed_area += previous.position.x * current.position.y -
      current.position.x * previous.position.y
  }
  {
    displacement: self.displacement(),
    path_length: self.path_length(),
    straightness: self.straightness(),
    mean_speed: self.speed(),
    peak_speed: peak,
    acceleration: self.acceleration(),
    heading_change,
    signed_area: signed_area / 2.0,
    duration: self.duration(),
    observed_frames: self.points.length(),
  }
}

///|
fn atan2(y : Double, x : Double) -> Double {
  if x > 0.0 && y > 0.0 {
    0.7853981633974483
  } else if x > 0.0 && y < 0.0 {
    -0.7853981633974483
  } else if x < 0.0 && y > 0.0 {
    2.356194490192345
  } else if x < 0.0 && y < 0.0 {
    -2.356194490192345
  } else if y > 0.0 {
    1.5707963267948966
  } else if y < 0.0 {
    -1.5707963267948966
  } else if x < 0.0 {
    3.141592653589793
  } else {
    0.0
  }
}

///|
fn angle_distance(left : Double, right : Double) -> Double {
  let mut difference = right - left
  while difference > 3.141592653589793 {
    difference -= 6.283185307179586
  }
  while difference < -3.141592653589793 {
    difference += 6.283185307179586
  }
  if difference < 0.0 {
    -difference
  } else {
    difference
  }
}

///|
pub fn aggregate_metrics(trajectories : Array[Trajectory]) -> AggregateMetrics {
  let mut total_distance = 0.0
  let mut total_path = 0.0
  let mut total_duration = 0
  let mut total_frames = 0
  let mut peak_speed = 0.0
  for trajectory in trajectories {
    let metrics = trajectory.metrics()
    total_distance += metrics.displacement
    total_path += metrics.path_length
    total_duration += metrics.duration
    total_frames += metrics.observed_frames
    if metrics.peak_speed > peak_speed {
      peak_speed = metrics.peak_speed
    }
  }
  let count = trajectories.length()
  {
    trajectory_count: count,
    mean_displacement: if count == 0 {
      0.0
    } else {
      total_distance / count.to_double()
    },
    mean_path_length: if count == 0 {
      0.0
    } else {
      total_path / count.to_double()
    },
    mean_duration: if count == 0 {
      0.0
    } else {
      total_duration.to_double() / count.to_double()
    },
    total_observed_frames: total_frames,
    peak_speed,
  }
}

///|
pub(all) struct AggregateMetrics {
  trajectory_count : Int
  mean_displacement : Double
  mean_path_length : Double
  mean_duration : Double
  total_observed_frames : Int
  peak_speed : Double
} derive(Debug)
