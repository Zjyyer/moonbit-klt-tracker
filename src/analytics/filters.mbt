///|
/// Query helpers for report rows.
pub fn rows_with_minimum_quality(
  rows : Array[TrajectoryReportRow],
  minimum : Double,
) -> Array[TrajectoryReportRow] {
  let result : Array[TrajectoryReportRow] = []
  for row in rows {
    if row.quality_score >= minimum {
      result.push(row)
    }
  }
  result
}

///|
pub fn rows_with_maximum_speed(
  rows : Array[TrajectoryReportRow],
  maximum : Double,
) -> Array[TrajectoryReportRow] {
  let result : Array[TrajectoryReportRow] = []
  for row in rows {
    if row.peak_speed <= maximum {
      result.push(row)
    }
  }
  result
}

///|
pub fn rows_between_frames(
  rows : Array[TrajectoryReportRow],
  first : Int,
  last : Int,
) -> Array[TrajectoryReportRow] {
  let result : Array[TrajectoryReportRow] = []
  for row in rows {
    if row.first_frame >= first && row.last_frame <= last {
      result.push(row)
    }
  }
  result
}

///|
pub fn rows_with_minimum_observations(
  rows : Array[TrajectoryReportRow],
  minimum : Int,
) -> Array[TrajectoryReportRow] {
  let result : Array[TrajectoryReportRow] = []
  for row in rows {
    if row.observation_count >= minimum {
      result.push(row)
    }
  }
  result
}

///|
pub fn rows_by_anomaly_name(
  rows : Array[TrajectoryReportRow],
  name : String,
) -> Array[TrajectoryReportRow] {
  let result : Array[TrajectoryReportRow] = []
  for row in rows {
    if report_anomaly_name(row.anomaly) == name {
      result.push(row)
    }
  }
  result
}

///|
pub fn sum_displacements(rows : Array[TrajectoryReportRow]) -> Double {
  let mut total = 0.0
  for row in rows {
    total += row.displacement
  }
  total
}

///|
pub fn sum_path_lengths(rows : Array[TrajectoryReportRow]) -> Double {
  let mut total = 0.0
  for row in rows {
    total += row.path_length
  }
  total
}

///|
pub fn mean_observations(rows : Array[TrajectoryReportRow]) -> Double {
  if rows.length() == 0 {
    0.0
  } else {
    let mut total = 0
    for row in rows {
      total += row.observation_count
    }
    total.to_double() / rows.length().to_double()
  }
}

///|
pub fn anomaly_rate(rows : Array[TrajectoryReportRow]) -> Double {
  if rows.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for row in rows {
      match row.anomaly {
        Normal => ()
        _ => count += 1
      }
    }
    count.to_double() / rows.length().to_double()
  }
}

///|
pub fn report_is_usable(
  rows : Array[TrajectoryReportRow],
  minimum_quality : Double,
) -> Bool {
  rows.length() > 0 &&
  report_quality(rows) >= minimum_quality &&
  anomaly_rate(rows) < 1.0
}

///|
pub fn rows_count_by_quality(
  rows : Array[TrajectoryReportRow],
  minimum : Double,
) -> Int {
  rows_with_minimum_quality(rows, minimum).length()
}

///|
pub fn rows_count_by_anomaly(
  rows : Array[TrajectoryReportRow],
  name : String,
) -> Int {
  rows_by_anomaly_name(rows, name).length()
}
