///|
pub(all) struct QualityConfig {
  minimum_confidence : Double
  maximum_speed : Double
} derive(Debug)

///|
pub fn QualityConfig::new(
  minimum_confidence : Double,
  maximum_speed : Double,
) -> Result[QualityConfig, TrajectoryError] {
  if minimum_confidence < 0.0 ||
    minimum_confidence > 1.0 ||
    maximum_speed < 0.0 ||
    !finite(minimum_confidence) ||
    !finite(maximum_speed) {
    Err(InvalidWindow)
  } else {
    Ok({ minimum_confidence, maximum_speed })
  }
}

///|
pub(all) struct QualitySummary {
  total_count : Int
  accepted_count : Int
  lost_count : Int
  rejected_count : Int
  mean_confidence : Double
  max_speed : Double
  gap_count : Int
  score : Double
} derive(Debug)

///|
pub fn Trajectory::quality(
  self : Trajectory,
  config : QualityConfig,
) -> QualitySummary {
  let mut accepted = 0
  let mut lost = 0
  let mut rejected = 0
  let mut confidence = 0.0
  let mut maximum_speed = 0.0
  for index, point in self.points {
    confidence += point.confidence
    match point.state {
      Accepted => accepted += 1
      Lost => lost += 1
      Rejected => rejected += 1
    }
    if index > 0 {
      let previous = self.points[index - 1]
      let speed = distance(previous.position, point.position) /
        (point.frame - previous.frame).to_double()
      if speed > maximum_speed {
        maximum_speed = speed
      }
    }
  }
  let count = self.points.length()
  let mean = confidence / count.to_double()
  let visibility = accepted.to_double() / count.to_double()
  let speed_score = if maximum_speed <= config.maximum_speed {
    1.0
  } else {
    config.maximum_speed / maximum_speed
  }
  {
    total_count: count,
    accepted_count: accepted,
    lost_count: lost,
    rejected_count: rejected,
    mean_confidence: mean,
    max_speed: maximum_speed,
    gap_count: self.gap_count(),
    score: (mean + visibility + speed_score) / 3.0,
  }
}
