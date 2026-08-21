///|
/// High-level dashboard values for human-readable acceptance reports.
pub(all) struct Dashboard {
  track_count : Int
  observation_count : Int
  normal_count : Int
  anomaly_count : Int
  mean_quality : Double
  best_track_id : Int?
  worst_track_id : Int?
} derive(Debug)

///|
pub fn dashboard(rows : Array[TrajectoryReportRow]) -> Dashboard {
  let mut normal = 0
  let mut anomaly = 0
  let mut quality = 0.0
  let mut best : TrajectoryReportRow? = None
  let mut worst : TrajectoryReportRow? = None
  for row in rows {
    match row.anomaly {
      Normal => normal += 1
      _ => anomaly += 1
    }
    quality += row.quality_score
    match best {
      None => best = Some(row)
      Some(current) =>
        if row.quality_score > current.quality_score {
          best = Some(row)
        }
    }
    match worst {
      None => worst = Some(row)
      Some(current) =>
        if row.quality_score < current.quality_score {
          worst = Some(row)
        }
    }
  }
  {
    track_count: rows.length(),
    observation_count: sum_observations(rows),
    normal_count: normal,
    anomaly_count: anomaly,
    mean_quality: if rows.length() == 0 {
      0.0
    } else {
      quality / rows.length().to_double()
    },
    best_track_id: match best {
      Some(row) => Some(row.id)
      None => None
    },
    worst_track_id: match worst {
      Some(row) => Some(row.id)
      None => None
    },
  }
}

///|
fn sum_observations(rows : Array[TrajectoryReportRow]) -> Int {
  let mut total = 0
  for row in rows {
    total += row.observation_count
  }
  total
}

///|
pub fn dashboard_label(value : Dashboard) -> String {
  if value.track_count == 0 {
    "empty"
  } else if value.anomaly_count == 0 {
    "clean"
  } else if value.normal_count > value.anomaly_count {
    "reviewable"
  } else {
    "attention_required"
  }
}
