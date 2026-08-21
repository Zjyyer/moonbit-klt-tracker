///|
/// A report row designed for CSV, JSON, and terminal presentation.
pub(all) struct TrajectoryReportRow {
  id : Int
  first_frame : Int
  last_frame : Int
  observation_count : Int
  displacement : Double
  path_length : Double
  mean_speed : Double
  peak_speed : Double
  quality_score : Double
  anomaly : ReportAnomaly
} derive(Debug)

///|
pub(all) enum ReportAnomaly {
  Normal
  ShortObservation
  LargeGap
  FastMotion
  LowConfidence
} derive(Debug, Eq)

///|
pub(all) struct ReportConfig {
  minimum_observations : Int
  maximum_gap_count : Int
  maximum_speed : Double
  minimum_quality : Double
} derive(Debug)

///|
pub fn ReportConfig::new(
  minimum_observations : Int,
  maximum_gap_count : Int,
  maximum_speed : Double,
  minimum_quality : Double,
) -> Result[ReportConfig, AggregateError] {
  if minimum_observations < 1 ||
    maximum_gap_count < 0 ||
    !finite(maximum_speed) ||
    !finite(minimum_quality) ||
    maximum_speed < 0.0 ||
    minimum_quality < 0.0 ||
    minimum_quality > 1.0 {
    Err(InvalidRange)
  } else {
    Ok({
      minimum_observations,
      maximum_gap_count,
      maximum_speed,
      minimum_quality,
    })
  }
}

///|
pub fn report_row(
  trajectory : @trajectory.Trajectory,
  config : ReportConfig,
) -> TrajectoryReportRow {
  let metrics = trajectory.metrics()
  let quality = trajectory.quality(
    @trajectory.QualityConfig::new(0.0, config.maximum_speed).unwrap(),
  )
  let anomaly = if metrics.observed_frames < config.minimum_observations {
    ShortObservation
  } else if trajectory.gap_count() > config.maximum_gap_count {
    LargeGap
  } else if metrics.peak_speed > config.maximum_speed {
    FastMotion
  } else if quality.score < config.minimum_quality {
    LowConfidence
  } else {
    Normal
  }
  {
    id: trajectory.id,
    first_frame: trajectory.first_frame().unwrap(),
    last_frame: trajectory.last_frame().unwrap(),
    observation_count: metrics.observed_frames,
    displacement: metrics.displacement,
    path_length: metrics.path_length,
    mean_speed: metrics.mean_speed,
    peak_speed: metrics.peak_speed,
    quality_score: quality.score,
    anomaly,
  }
}

///|
pub fn build_report(
  trajectories : Array[@trajectory.Trajectory],
  config : ReportConfig,
) -> Array[TrajectoryReportRow] {
  let rows : Array[TrajectoryReportRow] = []
  for trajectory in trajectories {
    rows.push(report_row(trajectory, config))
  }
  rows.sort_by(fn(left, right) { left.id.compare(right.id) })
  rows
}

///|
pub fn filter_anomalies(
  rows : Array[TrajectoryReportRow],
  anomaly : ReportAnomaly,
) -> Array[TrajectoryReportRow] {
  let result : Array[TrajectoryReportRow] = []
  for row in rows {
    if row.anomaly == anomaly {
      result.push(row)
    }
  }
  result
}

///|
pub fn report_quality(rows : Array[TrajectoryReportRow]) -> Double {
  if rows.length() == 0 {
    return 0.0
  }
  let mut score = 0.0
  for row in rows {
    score += row.quality_score
  }
  score / rows.length().to_double()
}

///|
pub fn anomaly_counts(rows : Array[TrajectoryReportRow]) -> Array[Int] {
  let counts : Array[Int] = []
  for _ in 0..<5 {
    counts.push(0)
  }
  for row in rows {
    let index = match row.anomaly {
      Normal => 0
      ShortObservation => 1
      LargeGap => 2
      FastMotion => 3
      LowConfidence => 4
    }
    counts[index] += 1
  }
  counts
}

///|
pub fn report_header() -> String {
  "id,first_frame,last_frame,observation_count,displacement,path_length,mean_speed,peak_speed,quality_score,anomaly"
}

///|
pub fn report_row_csv(row : TrajectoryReportRow) -> String {
  let output = StringBuilder()
  output.write_object(row.id)
  output.write_string(",")
  output.write_object(row.first_frame)
  output.write_string(",")
  output.write_object(row.last_frame)
  output.write_string(",")
  output.write_object(row.observation_count)
  output.write_string(",")
  output.write_object(row.displacement)
  output.write_string(",")
  output.write_object(row.path_length)
  output.write_string(",")
  output.write_object(row.mean_speed)
  output.write_string(",")
  output.write_object(row.peak_speed)
  output.write_string(",")
  output.write_object(row.quality_score)
  output.write_string(",")
  output.write_string(report_anomaly_name(row.anomaly))
  output.to_string()
}

///|
pub fn report_anomaly_name(anomaly : ReportAnomaly) -> String {
  match anomaly {
    Normal => "normal"
    ShortObservation => "short_observation"
    LargeGap => "large_gap"
    FastMotion => "fast_motion"
    LowConfidence => "low_confidence"
  }
}
